mvn clean install
onos-app localhost install! target/echoname-1.0-SNAPSHOT.oar
onos-netcfg localhost NameConfig.json

# http://localhost:8181/onos/ui
onos-create-app
mvn clean install

cd $ONOS_ROOT
ok clean debug

# Run ring_topo.py to build the topology
sudo mn --custom=ring_topo.py --topo=mytopo \
--controller=remote,ip=127.0.0.1,port=6653 \
--switch=ovs,protocols=OpenFlow14

# Upload config file to ONOS
onos-netcfg localhost hostconfig.json

# Build, install, and activate your App
onos-app localhost install! target/groupmeter-1.0-SNAPSHOT.oar

mvn clean install && \
onos-app localhost deactivate nycu.winlab.groupmeter && \
onos-app localhost uninstall nycu.winlab.groupmeter && \
onos-app localhost install! target/groupmeter-1.0-SNAPSHOT.oar

# Use h1 as iperf UDP client and h2 as iperf UDP server to test your traffic
ps aux | grep mininet
sudo mnexec -a <h2_PID> iperf -s -u
# mininet> h2 iperf -s -u &

mininet> h1 ping h2 -c 10
mininet> h1 iperf -c 10.6.1.2 -u -b 512K
mininet> h1 iperf -c 10.6.1.2 -u -b 1M
mininet> h1 iperf -c 10.6.1.2 -u -b 2M
mininet> h1 iperf -c 10.6.1.2 -u -b 512M

# Monitor s1 and s4 interface
mininet> sh ovs-ofctl dump-ports -O OpenFlow14 s1
mininet> sh ovs-ofctl dump-ports -O OpenFlow14 s4

# Turn down s1–s2 link
mininet> link s1 s2 down

# Run iperf UDP on h1 to h2
mininet> h1 ping h2 -c 10
mininet> h1 iperf -c 10.6.1.2 -u -b 512K
mininet> h1 iperf -c 10.6.1.2 -u -b 1M
mininet> h1 iperf -c 10.6.1.2 -u -b 2M
mininet> h1 iperf -c 10.6.1.2 -u -b 512M

# Monitor s1 and s4 interface
mininet> sh ovs-ofctl dump-ports -O OpenFlow14 s1
mininet> sh ovs-ofctl dump-ports -O OpenFlow14 s4

scp -P 11003 -r sdn@dorm:/home/sdn/groupmeter .
