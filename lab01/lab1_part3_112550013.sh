sudo mn --custom=lab1_part3_112550013.py \
--topo=topo_part3_112550013 \
--controller=remote,ip=127.0.0.1:6653 \
--switch=ovs,protocols=OpenFlow14

mininet> dump
mininet> h1 ifconfig
mininet> h2 ifconfig
mininet> h3 ifconfig
mininet> h4 ifconfig
mininet> h5 ifconfig
