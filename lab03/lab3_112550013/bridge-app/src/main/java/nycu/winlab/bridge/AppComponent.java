/*
 * Copyright 2024-present Open Networking Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package nycu.winlab;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.onosproject.core.ApplicationId;
import org.onosproject.core.CoreService;

import org.onosproject.net.flow.FlowRuleService;
import org.onosproject.net.flow.DefaultTrafficSelector;
import org.onosproject.net.flow.DefaultTrafficTreatment;
import org.onosproject.net.flow.TrafficSelector;
import org.onosproject.net.flow.TrafficTreatment;

import org.onosproject.net.flowobjective.FlowObjectiveService;
import org.onosproject.net.flowobjective.ForwardingObjective;
import org.onosproject.net.flowobjective.DefaultForwardingObjective;

import org.onosproject.net.packet.InboundPacket;
import org.onosproject.net.packet.PacketContext;
import org.onosproject.net.packet.PacketProcessor;
import org.onosproject.net.packet.PacketService;
import org.onosproject.net.packet.PacketPriority;

import org.onlab.packet.Ethernet;
import org.onlab.packet.MacAddress;
import org.onosproject.net.ConnectPoint;
import org.onosproject.net.DeviceId;
import org.onosproject.net.PortNumber;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ONOS Learning Bridge Application Component.
 */
@Component(immediate = true)
public class AppComponent {

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private PacketService packetService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private FlowRuleService flowRuleService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private FlowObjectiveService flowObjectiveService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private CoreService coreService;

    private static final int FLOW_TIMEOUT = 30;
    private static final int FLOW_PRIORITY = 30;

    private ApplicationId appId;
    private final PacketProcessor processor = new BridgePacketProcessor();

    private final Map<DeviceId, Map<MacAddress, PortNumber>> forwardingTable = new ConcurrentHashMap<>();

    private final Logger log = LoggerFactory.getLogger(getClass());

    @Activate
    protected void activate() {
        appId = coreService.registerApplication("nycu.winlab.bridge");
        packetService.addProcessor(processor, PacketProcessor.director(2));
        requestIntercepts();
        log.info("Started Learning Bridge Application with App ID `{}`", appId.id());
    }

    @Deactivate
    protected void deactivate() {
        withdrawIntercepts();
        packetService.removeProcessor(processor);
        flowRuleService.removeFlowRulesById(appId);
        forwardingTable.clear();
        log.info("Stopped Learning Bridge Application");
    }

    private void requestIntercepts() {
        TrafficSelector ipv4Selector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_IPV4)
                .build();

        packetService.requestPackets(ipv4Selector, PacketPriority.REACTIVE, appId);

        TrafficSelector arpSelector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();

        packetService.requestPackets(arpSelector, PacketPriority.REACTIVE, appId);
    }

    private void withdrawIntercepts() {
        TrafficSelector ipv4Selector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_IPV4)
                .build();

        packetService.cancelPackets(ipv4Selector, PacketPriority.REACTIVE, appId);

        TrafficSelector arpSelector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();

        packetService.cancelPackets(arpSelector, PacketPriority.REACTIVE, appId);
    }

    private class BridgePacketProcessor implements PacketProcessor {

        @Override
        public void process(PacketContext context) {
            if (context.isHandled()) {
                return;
            }

            InboundPacket pkt = context.inPacket();
            Ethernet ethPkt = pkt.parsed();

            if (ethPkt == null) {
                return;
            }

            if (isControlPacket(ethPkt)) {
                return;
            }

            ConnectPoint cp = pkt.receivedFrom();
            DeviceId deviceId = cp.deviceId();
            PortNumber inPort = cp.port();
            MacAddress srcMac = ethPkt.getSourceMAC();
            MacAddress dstMac = ethPkt.getDestinationMAC();

            forwardingTable.computeIfAbsent(deviceId, k -> new ConcurrentHashMap<>());
            Map<MacAddress, PortNumber> macTable = forwardingTable.get(deviceId);

            if (!macTable.containsKey(srcMac)) {
                macTable.put(srcMac, inPort);
                log.info("Add an entry to the port table of `{}`. MAC address: `{}` => Port: `{}`.",
                        deviceId, srcMac, inPort);
            }

            PortNumber outPort = macTable.get(dstMac);

            if (outPort == null) {
                flood(context);
                log.info("MAC address `{}` is missed on `{}`. Flood the packet.", dstMac, deviceId);
            } else if (!outPort.equals(inPort)) {
                installFlowRule(deviceId, srcMac, dstMac, outPort);
                packetOut(context, outPort);
                log.info("MAC address `{}` is matched on `{}`. Install a flow rule.", dstMac, deviceId);
            } else {
                context.block();
            }
        }

        private void installFlowRule(DeviceId deviceId, MacAddress srcMac, MacAddress dstMac, PortNumber outPort) {
            TrafficSelector selector = DefaultTrafficSelector.builder()
                    .matchEthSrc(srcMac)
                    .matchEthDst(dstMac)
                    .build();

            TrafficTreatment treatment = DefaultTrafficTreatment.builder()
                    .setOutput(outPort)
                    .build();

            ForwardingObjective forwardingObjective = DefaultForwardingObjective.builder()
                    .withSelector(selector)
                    .withTreatment(treatment)
                    .withPriority(FLOW_PRIORITY)
                    .withFlag(ForwardingObjective.Flag.VERSATILE)
                    .makeTemporary(FLOW_TIMEOUT)
                    .fromApp(appId)
                    .add();

            flowObjectiveService.forward(deviceId, forwardingObjective);
        }

        private void packetOut(PacketContext context, PortNumber outPort) {
            context.treatmentBuilder().setOutput(outPort);
            context.send();
        }

        private void flood(PacketContext context) {
            packetOut(context, PortNumber.FLOOD);
        }

        private boolean isControlPacket(Ethernet ethPkt) {
            short etherType = ethPkt.getEtherType();
            return etherType == Ethernet.TYPE_LLDP || etherType == Ethernet.TYPE_BSN;
        }
    }
}
