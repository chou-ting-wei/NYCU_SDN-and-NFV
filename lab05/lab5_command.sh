# Prepare Docker images
docker build -t host -f host.Dockerfile .
docker pull frrouting/frr-debian
docker images

make
make clean

# Connect to ONOS CLI
ssh -o "StrictHostKeyChecking=no" \
    -o GlobalKnownHostsFile=/dev/null \
    -o UserKnownHostsFile=/dev/null \
    onos@localhost -p 8101

# Test Your App
docker exec h1 ifconfig
docker exec h2 ifconfig
docker exec h3 ifconfig
docker exec h4 ifconfig
onos@root > app activate fwd
docker exec -it h1 ping 172.21.0.3 -c 3
docker exec -it h1 ping 172.22.0.3 -c 3
docker exec -it h1 ping 172.24.0.3 -c 3

docker exec -it R1 bash
root@R1:/# vtysh
R1# show ip bgp

onos@root > app activate fpm
onos@root > routes