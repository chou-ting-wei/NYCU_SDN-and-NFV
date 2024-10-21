sudo mn --controller=remote,127.0.0.1:6653 --switch=ovs,protocols=OpenFlow14
mininet> h1 ping h2

sudo mn --custom=demo_part2_112550013.py \
--topo=topo_part2_112550013 \
--controller=remote,ip=127.0.0.1:6653 \
--switch=ovs,protocols=OpenFlow14

curl -u onos:rocks -X POST -H 'Content-Type: application/json' -d @flows_s1-1_112550013.json \
'http://localhost:8181/onos/v1/flows/of:0000000000000001'

curl -u onos:rocks -X POST -H 'Content-Type: application/json' -d @flows_s1-2_112550013.json \
'http://localhost:8181/onos/v1/flows/of:0000000000000001'

curl -u onos:rocks -X POST -H 'Content-Type: application/json' -d @flows_s1-3_112550013.json \
'http://localhost:8181/onos/v1/flows/of:0000000000000001'
