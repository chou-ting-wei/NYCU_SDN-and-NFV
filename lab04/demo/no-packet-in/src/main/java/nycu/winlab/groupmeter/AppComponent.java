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
package nycu.winlab.groupmeter;

import static org.onosproject.net.config.NetworkConfigEvent.Type.CONFIG_ADDED;
import static org.onosproject.net.config.NetworkConfigEvent.Type.CONFIG_UPDATED;
import static org.onosproject.net.config.basics.SubjectFactories.APP_SUBJECT_FACTORY;

import org.onosproject.cfg.ComponentConfigService;
// import org.osgi.service.component.ComponentContext;
import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Deactivate;
// import org.osgi.service.component.annotations.Modified;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.onosproject.core.ApplicationId;
import org.onosproject.core.CoreService;

import org.onosproject.net.DeviceId;
import org.onosproject.net.PortNumber;
import org.onosproject.net.ConnectPoint;
import org.onosproject.net.FilteredConnectPoint;

import org.onosproject.net.config.ConfigFactory;
import org.onosproject.net.config.NetworkConfigEvent;
import org.onosproject.net.config.NetworkConfigListener;
import org.onosproject.net.config.NetworkConfigRegistry;

import org.onosproject.net.flow.DefaultTrafficSelector;
import org.onosproject.net.flow.DefaultTrafficTreatment;
import org.onosproject.net.flow.TrafficSelector;
import org.onosproject.net.flow.TrafficTreatment;
import org.onosproject.net.flow.FlowRuleService;
// import org.onosproject.net.flow.FlowRule;
// import org.onosproject.net.flow.DefaultFlowRule;

import org.onosproject.net.flowobjective.FlowObjectiveService;
import org.onosproject.net.flowobjective.ForwardingObjective;
import org.onosproject.net.flowobjective.DefaultForwardingObjective;

import org.onosproject.core.GroupId;
import org.onosproject.net.group.Group;
import org.onosproject.net.group.GroupBucket;
import org.onosproject.net.group.DefaultGroupBucket;
import org.onosproject.net.group.DefaultGroupDescription;
import org.onosproject.net.group.DefaultGroupKey;
import org.onosproject.net.group.GroupBuckets;
import org.onosproject.net.group.GroupDescription;
import org.onosproject.net.group.GroupKey;
import org.onosproject.net.group.GroupService;

import org.onosproject.net.intent.IntentService;
import org.onosproject.net.intent.PointToPointIntent;

import org.onosproject.net.meter.Band;
import org.onosproject.net.meter.DefaultBand;
import org.onosproject.net.meter.DefaultMeterRequest;
import org.onosproject.net.meter.MeterRequest;
import org.onosproject.net.meter.MeterService;
import org.onosproject.net.meter.Meter;
import org.onosproject.net.meter.MeterId;

import org.onlab.packet.Ethernet;
import org.onlab.packet.ARP;
import org.onlab.packet.Ip4Address;
import org.onlab.packet.MacAddress;

import org.onosproject.net.packet.PacketContext;
import org.onosproject.net.packet.PacketProcessor;
import org.onosproject.net.packet.PacketService;
import org.onosproject.net.packet.InboundPacket;
import org.onosproject.net.packet.OutboundPacket;
import org.onosproject.net.packet.DefaultOutboundPacket;
import org.onosproject.net.packet.PacketPriority;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Map;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Collections;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

// import static org.onlab.util.Tools.get;

import org.onosproject.net.edge.EdgePortService;

/**
 * ONOS Application Component for Group Meter and Proxy ARP.
 */
@Component(immediate = true)
public class AppComponent {

    private final Logger log = LoggerFactory.getLogger(getClass());
    private final NameConfigListener cfgListener = new NameConfigListener();
    private ApplicationId appId;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected NetworkConfigRegistry cfgService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected ComponentConfigService componentConfigService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected CoreService coreService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected GroupService groupService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected MeterService meterService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected IntentService intentService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected PacketService packetService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected FlowRuleService flowRuleService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    private FlowObjectiveService flowObjectiveService;

    @Reference(cardinality = ReferenceCardinality.MANDATORY)
    protected EdgePortService edgePortService;

    private final ConfigFactory<ApplicationId, NameConfig> factory = new ConfigFactory<ApplicationId, NameConfig>(
            APP_SUBJECT_FACTORY, NameConfig.class, "informations") {
        @Override
        public NameConfig createConfig() {
            return new NameConfig();
        }
    };

    private final PacketProcessor processor = new ProxyArpProcessor();
    private final Map<Ip4Address, MacAddress> arpTable = new ConcurrentHashMap<>();
    private final Map<MacAddress, ConnectPoint> macToPortMap = new ConcurrentHashMap<>();

    private final ScheduledExecutorService executor = Executors.newSingleThreadScheduledExecutor();

    GroupKey groupKey = new DefaultGroupKey("failoverGroup".getBytes());
    DeviceId deviceId_s1 = DeviceId.deviceId("of:0000000000000001");
    DeviceId deviceId_s2 = DeviceId.deviceId("of:0000000000000002");
    DeviceId deviceId_s3 = DeviceId.deviceId("of:0000000000000003");
    DeviceId deviceId_s4 = DeviceId.deviceId("of:0000000000000004");
    DeviceId deviceId_s5 = DeviceId.deviceId("of:0000000000000005");

    @Activate
    protected void activate() {
        appId = coreService.registerApplication("nycu.winlab.groupmeter");
        cfgService.addListener(cfgListener);
        cfgService.registerConfigFactory(factory);

        setupFailoverGroup();
        setupDropMeter();
        executor.schedule(() -> {
            setupFlowRuleWithGroup();
            setupFlowRuleWithMeter();
            setupIntentsWithConfig(null, false, true);
        }, 3, TimeUnit.SECONDS);

        packetService.addProcessor(processor, PacketProcessor.director(3));
        requestIntercepts();
        log.info("Started Group Meter Application with Proxy ARP and App ID `{}`", appId.id());
    }

    @Deactivate
    protected void deactivate() {
        cfgService.removeListener(cfgListener);
        cfgService.unregisterConfigFactory(factory);
        withdrawIntercepts();
        packetService.removeProcessor(processor);
        executor.shutdown();
        log.info("Stopped Group Meter Application with Proxy ARP");
    }

    private class NameConfigListener implements NetworkConfigListener {
        @Override
        public void event(NetworkConfigEvent event) {
            if ((event.type() == CONFIG_ADDED || event.type() == CONFIG_UPDATED)
                && event.configClass().equals(NameConfig.class)) {
                NameConfig config = cfgService.getConfig(appId, NameConfig.class);
                if (config != null) {
                    log.info("ConnectPoint_h1: {}, ConnectPoint_h2: {}", config.host1ConnectPoint(),
                        config.host2ConnectPoint());
                    log.info("MacAddress_h1: {}, MacAddress_h2: {}", config.mac1(), config.mac2());
                    log.info("IpAddress_h1: {}, IpAddress_h2: {}", config.ip1(), config.ip2());
                }
            }
        }
    }

    private void setupFailoverGroup() {
        List<GroupBucket> buckets = new ArrayList<>();

        buckets.add(DefaultGroupBucket.createFailoverGroupBucket(
            DefaultTrafficTreatment.builder().setOutput(PortNumber.portNumber(2)).build(),
            PortNumber.portNumber(2),
            GroupId.valueOf(0)));
        buckets.add(DefaultGroupBucket.createFailoverGroupBucket(
            DefaultTrafficTreatment.builder().setOutput(PortNumber.portNumber(3)).build(),
            PortNumber.portNumber(3),
            GroupId.valueOf(0)));

        GroupBuckets groupBuckets = new GroupBuckets(buckets);

        GroupDescription groupDesc = new DefaultGroupDescription(deviceId_s1,
                                         GroupDescription.Type.FAILOVER, groupBuckets,
                                         groupKey, null, appId);

        groupService.addGroup(groupDesc);
    }

    private void setupFlowRuleWithGroup() {
        Group group = groupService.getGroup(deviceId_s1, groupKey);

        if (group != null) {
            GroupId groupId = group.id();

            TrafficSelector selector = DefaultTrafficSelector.builder()
                .matchInPort(PortNumber.portNumber(1))
                .matchEthType(Ethernet.TYPE_IPV4)
                .build();

            TrafficTreatment treatment = DefaultTrafficTreatment.builder()
                .group(groupId)
                .build();

            ForwardingObjective forwardingObjective = DefaultForwardingObjective.builder()
                .withSelector(selector)
                .withTreatment(treatment)
                .withPriority(40010)
                .withFlag(ForwardingObjective.Flag.VERSATILE)
                .makePermanent()
                .fromApp(appId)
                .add();

            flowObjectiveService.forward(deviceId_s1, forwardingObjective);

            log.info("Failover Group set for device {}", deviceId_s1);
        } else {
            log.error("Failed to retrieve the group on device {}", deviceId_s1);
        }
    }

    MeterId meterId = null;

    private void setupDropMeter() {
        Band dropBand = DefaultBand.builder()
            .ofType(Band.Type.DROP)
            .withRate(512)
            .burstSize(1024)
            .build();

        MeterRequest meterReq = DefaultMeterRequest.builder()
            .forDevice(deviceId_s4)
            .fromApp(appId)
            .withUnit(Meter.Unit.KB_PER_SEC)
            .withBands(Collections.singletonList(dropBand))
            .burst()
            .add();

        Meter meter = meterService.submit(meterReq);
        meterId = meter.id();
    }

    private void setupFlowRuleWithMeter() {
        NameConfig config = cfgService.getConfig(appId, NameConfig.class);
        if (config == null) {
            log.warn("NameConfig is not available; cannot set up flow rule with meter.");
            return;
        }

        if (meterId != null) {
            TrafficSelector selector = DefaultTrafficSelector.builder()
                .matchEthSrc(config.mac1())
                .build();

            TrafficTreatment treatment = DefaultTrafficTreatment.builder()
                .meter(meterId)
                .setOutput(PortNumber.portNumber(2))
                .build();

            ForwardingObjective forwardingObjective = DefaultForwardingObjective.builder()
                .withSelector(selector)
                .withTreatment(treatment)
                .withPriority(40010)
                .withFlag(ForwardingObjective.Flag.VERSATILE)
                .makePermanent()
                .fromApp(appId)
                .add();

            flowObjectiveService.forward(deviceId_s4, forwardingObjective);

            log.info("Flow rule with METER_ID set for device {}", deviceId_s4);
        } else {
            log.error("Failed to retrieve the meter on device {}", deviceId_s4);
        }
    }

    private void setupIntentsWithConfig(ConnectPoint ingressConnectPoint, boolean toH2, boolean forH3) {
        NameConfig config = cfgService.getConfig(appId, NameConfig.class);
        if (config == null) {
            log.warn("NameConfig is not available; cannot set up intents.");
            return;
        }

        if (forH3) {
            TrafficSelector selector1 = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac3())
                    .build();

            PointToPointIntent intent1 = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector1)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(config.host1ConnectPoint()))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host3ConnectPoint()))
                    .build();

            intentService.submit(intent1);
            logIntentInfo(config.host1ConnectPoint(), config.host3ConnectPoint());

            TrafficSelector selector2 = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac3())
                    .build();

            PointToPointIntent intent2 = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector2)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(config.host2ConnectPoint()))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host3ConnectPoint()))
                    .build();

            intentService.submit(intent2);
            logIntentInfo(config.host2ConnectPoint(), config.host3ConnectPoint());

            TrafficSelector selector3 = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac1())
                    .build();

            PointToPointIntent intent3 = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector3)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(config.host3ConnectPoint()))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host1ConnectPoint()))
                    .build();

            intentService.submit(intent3);
            logIntentInfo(config.host3ConnectPoint(), config.host1ConnectPoint());

            TrafficSelector selector4 = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac2())
                    .build();

            PointToPointIntent intent4 = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector4)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(config.host3ConnectPoint()))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host2ConnectPoint()))
                    .build();

            intentService.submit(intent4);
            logIntentInfo(config.host3ConnectPoint(), config.host2ConnectPoint());
        } else if (toH2) {
            TrafficSelector selector = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac2())
                    .build();

            PointToPointIntent intent = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(ingressConnectPoint))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host2ConnectPoint()))
                    .build();

            intentService.submit(intent);
            logIntentInfo(ingressConnectPoint, config.host2ConnectPoint());
        } else {
            TrafficSelector selector = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac1())
                    .build();

            PointToPointIntent intent = PointToPointIntent.builder()
                    .appId(appId)
                    .selector(selector)
                    .treatment(DefaultTrafficTreatment.emptyTreatment())
                    .filteredIngressPoint(new FilteredConnectPoint(ingressConnectPoint))
                    .filteredEgressPoint(new FilteredConnectPoint(config.host1ConnectPoint()))
                    .build();

            intentService.submit(intent);
            logIntentInfo(ingressConnectPoint, config.host1ConnectPoint());
        }
    }

    private void logIntentInfo(ConnectPoint ingress, ConnectPoint egress) {
        log.info("Intent `{}`, port `{}` => `{}`, port `{}` is submitted.",
                 ingress.deviceId(), ingress.port(),
                 egress.deviceId(), egress.port());
    }

    private void requestIntercepts() {
        TrafficSelector arpSelector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();
        packetService.requestPackets(arpSelector, PacketPriority.REACTIVE, appId);

        NameConfig config = cfgService.getConfig(appId, NameConfig.class);
        if (config != null) {
            TrafficSelector h2Selector = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac2())
                    .build();
            packetService.requestPackets(h2Selector, PacketPriority.REACTIVE, appId);

            TrafficSelector h2ToH1Selector = DefaultTrafficSelector.builder()
                    .matchEthSrc(config.mac2())
                    .matchEthDst(config.mac1())
                    .build();
            packetService.requestPackets(h2ToH1Selector, PacketPriority.REACTIVE, appId);
        } else {
            log.warn("NameConfig is not available; cannot set up packet intercepts for h2.");
        }
    }

    private void withdrawIntercepts() {
        TrafficSelector arpSelector = DefaultTrafficSelector.builder()
                .matchEthType(Ethernet.TYPE_ARP)
                .build();
        packetService.cancelPackets(arpSelector, PacketPriority.REACTIVE, appId);

        NameConfig config = cfgService.getConfig(appId, NameConfig.class);
        if (config != null) {
            TrafficSelector h2Selector = DefaultTrafficSelector.builder()
                    .matchEthDst(config.mac2())
                    .build();
            packetService.cancelPackets(h2Selector, PacketPriority.REACTIVE, appId);

            TrafficSelector h2ToH1Selector = DefaultTrafficSelector.builder()
                    .matchEthSrc(config.mac2())
                    .matchEthDst(config.mac1())
                    .build();
            packetService.cancelPackets(h2ToH1Selector, PacketPriority.REACTIVE, appId);
        }
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

            if (ethPkt.getEtherType() == Ethernet.TYPE_ARP) {
                processArpPacket(context);
                return;
            }

            NameConfig config = cfgService.getConfig(appId, NameConfig.class);
            if (config == null) {
                log.warn("NameConfig is not available; cannot process packets.");
                return;
            }

            MacAddress h2Mac = config.mac2();
            MacAddress h1Mac = config.mac1();
            ConnectPoint ingressConnectPoint = pkt.receivedFrom();
            DeviceId ingressDeviceId = ingressConnectPoint.deviceId();

            if (ethPkt.getDestinationMAC().equals(h2Mac)) {
                if (ingressDeviceId.equals(DeviceId.deviceId("of:0000000000000002")) ||
                    ingressDeviceId.equals(DeviceId.deviceId("of:0000000000000005"))) {
                    log.info("Packet destined to h2 received at {}", ingressConnectPoint);
                    setupIntentsWithConfig(ingressConnectPoint, true, false);
                    context.block();
                } else {
                    log.info("Packet destined to h2 received at {}, not from s2 or s5, ignoring", ingressConnectPoint);
                }
            } else if (ethPkt.getSourceMAC().equals(h2Mac) && ethPkt.getDestinationMAC().equals(h1Mac)) {
                log.info("Packet from h2 to h1 received at {}", ingressConnectPoint);
                setupIntentsWithConfig(ingressConnectPoint, false, false);
                context.block();
            }
        }

        private void processArpPacket(PacketContext context) {
            InboundPacket pkt = context.inPacket();
            Ethernet ethPkt = pkt.parsed();

            if (ethPkt == null || ethPkt.getEtherType() != Ethernet.TYPE_ARP) {
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
                macToPortMap.put(srcMac, inPort);
                arpTable.put(srcIp, srcMac);

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
