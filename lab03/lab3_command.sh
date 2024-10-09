# http://localhost:8181/onos/ui
onos-create-app
mvn clean install

# Learning Bridge Function
cd $ONOS_ROOT
ok clean debug
onos-app localhost install! target/bridge-app-1.0-SNAPSHOT.oar

mvn clean install && \
onos-app localhost deactivate nycu.winlab.bridge && \
onos-app localhost uninstall nycu.winlab.bridge && \
onos-app localhost install! target/bridge-app-1.0-SNAPSHOT.oar

# Learning Bridge Function with tree (depth=2) topology. (10%)
sudo mn --controller=remote,127.0.0.1:6653 \
--topo=tree,depth=2 \
--switch=ovs,protocols=OpenFlow14

# Learning Bridge Function with tree (depth=3~5) topology. (10%)
sudo mn --controller=remote,127.0.0.1:6653 \
--topo=tree,depth=3 \
--switch=ovs,protocols=OpenFlow14

sudo mn --controller=remote,127.0.0.1:6653 \
--topo=tree,depth=4 \
--switch=ovs,protocols=OpenFlow14

sudo mn --controller=remote,127.0.0.1:6653 \
--topo=tree,depth=5 \
--switch=ovs,protocols=OpenFlow14

scp -P 11003 -r sdn@dorm:/home/sdn/bridge-app .

# ARP Proxy
cd $ONOS_ROOT
ok clean debug
onos-app localhost install! target/ProxyArp-1.0-SNAPSHOT.oar

mvn clean install && \
onos-app localhost deactivate nycu.winlab.ProxyArp && \
onos-app localhost uninstall nycu.winlab.ProxyArp && \
onos-app localhost install! target/ProxyArp-1.0-SNAPSHOT.oar

# Work properly at least in tree (depth=3, fanout=3) topology (40%)
sudo mn --controller=remote,127.0.0.1:6653 \
--topo=tree,depth=3,fanout=3 \
--switch=ovs,protocols=OpenFlow14

scp -P 11003 -r sdn@dorm:/home/sdn/ProxyArp .