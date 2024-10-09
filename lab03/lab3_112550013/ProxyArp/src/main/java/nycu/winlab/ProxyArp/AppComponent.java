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

import org.onosproject.net.packet.PacketContext;
import org.onosproject.net.packet.PacketProcessor;
import org.onosproject.net.packet.PacketService;
import org.onosproject.net.packet.InboundPacket;
import org.onosproject.net.packet.OutboundPacket;
import org.onosproject.net.packet.DefaultOutboundPacket;
import org.onosproject.net.packet.PacketPriority;

import org.onosproject.net.edge.EdgePortService;
import org.onosproject.net.ConnectPoint;

import org.onosproject.net.flow.DefaultTrafficSelector;
import org.onosproject.net.flow.DefaultTrafficTreatment;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.TrafficSelector;

import org.onlab.packet.Ethernet;
import org.onlab.packet.ARP;
import org.onlab.packet.Ip4Address;
import org.onlab.packet.MacAddress;

import java.nio.ByteBuffer;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ONOS Application Component for Proxy ARP.
 */
@Component(immediate = true)
public class AppComponent {

    private final Logger log = LoggerFactory.getLogger(getClass());

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private CoreService coreService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private PacketService packetService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private EdgePortService edgePortService;

    private ApplicationId appId;
    private final PacketProcessor processor = new ProxyArpProcessor();

    private final Map<Ip4Address, MacAddress> arpTable = new ConcurrentHashMap<>();
    private final Map<MacAddress, ConnectPoint> macToPortMap = new ConcurrentHashMap<>();

    @Activate
    protected void activate() {
        appId = coreService.registerApplication("nycu.winlab.ProxyArp");
        packetService.addProcessor(processor, PacketProcessor.director(3));
        requestIntercepts();
        log.info("Started Proxy ARP Application with App ID `{}`", appId.id());
    }

    @Deactivate
    protected void deactivate() {
        withdrawIntercepts();
        packetService.removeProcessor(processor);
        log.info("Stopped Proxy ARP Application");
    }

    private void requestIntercepts() {
        TrafficSelector selector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();
        packetService.requestPackets(selector, PacketPriority.REACTIVE, appId);
    }

    private void withdrawIntercepts() {
        TrafficSelector selector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();
        packetService.cancelPackets(selector, PacketPriority.REACTIVE, appId);
    }

    private class ProxyArpProcessor implements PacketProcessor {

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

            if (ethPkt.getEtherType() != Ethernet.TYPE_ARP) {
                return;
            }

            ARP arpPacket = (ARP) ethPkt.getPayload();

            if (arpPacket.getProtocolType() != ARP.PROTO_TYPE_IP) {
                return;
            }

            ConnectPoint inPort = pkt.receivedFrom();
            MacAddress srcMac = ethPkt.getSourceMAC();
            Ip4Address srcIp = Ip4Address.valueOf(arpPacket.getSenderProtocolAddress());
            Ip4Address dstIp = Ip4Address.valueOf(arpPacket.getTargetProtocolAddress());

            macToPortMap.putIfAbsent(srcMac, inPort);
            arpTable.putIfAbsent(srcIp, srcMac);

            if (arpPacket.getOpCode() == ARP.OP_REQUEST) {
                MacAddress targetMac = arpTable.get(dstIp);
                if (targetMac == null) {
                    log.info("TABLE MISS. Send request to edge ports");
                    flood(ethPkt, inPort);
                } else {
                    log.info("TABLE HIT. Requested MAC = {}", targetMac);
                    Ethernet arpReply = ARP.buildArpReply(dstIp, targetMac, ethPkt);
                    sendPacket(arpReply, inPort);
                }
            } else if (arpPacket.getOpCode() == ARP.OP_REPLY) {
                log.info("RECV REPLY. Requested MAC = {}", srcMac);
                arpTable.put(srcIp, srcMac);
                macToPortMap.put(srcMac, inPort);

                MacAddress requesterMac = arpTable.get(dstIp);
                ConnectPoint requesterPort = macToPortMap.get(requesterMac);

                if (requesterPort != null) {
                    sendPacket(ethPkt, requesterPort);
                }
            }
        }

        private void flood(Ethernet ethPkt, ConnectPoint inPort) {
            for (ConnectPoint cp : edgePortService.getEdgePoints()) {
                if (!cp.equals(inPort)) {
                    sendPacket(ethPkt, cp);
                }
            }
        }

        private void sendPacket(Ethernet ethPkt, ConnectPoint outPort) {
            TrafficTreatment treatment = DefaultTrafficTreatment.builder()
                    .setOutput(outPort.port())
                    .build();
            OutboundPacket outboundPacket = new DefaultOutboundPacket(
                    outPort.deviceId(),
                    treatment,
                    ByteBuffer.wrap(ethPkt.serialize()));
            packetService.emit(outboundPacket);
        }
    }
}
