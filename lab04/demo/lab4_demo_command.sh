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
onos-app localhost install! target/no-packet-in-1.0-SNAPSHOT.oar

mvn clean install && \
onos-app localhost deactivate nycu.winlab.groupmeter && \
onos-app localhost uninstall nycu.winlab.groupmeter && \
onos-app localhost install! target/no-packet-in-1.0-SNAPSHOT.oar

mininet> pingall

scp -P 11003 -r sdn@dorm:/home/sdn/no-packet-in .
