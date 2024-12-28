#!/bin/bash
# if [ "$EUID" -ne 0 ]
#   then echo "Please run as root"
#   exit
# fi

for host in h01 h02 er01 speaker ONOS; do
    sudo docker kill --signal=9 $host &>/dev/null
    sudo docker rm $host &>/dev/null
done

sudo ovs-vsctl --if-exists del-br ovs1 &>/dev/null
sudo ovs-vsctl --if-exists del-br ovs2 &>/dev/null
sudo ovs-vsctl --if-exists del-br bre1 &>/dev/null

sudo basename -a /sys/class/net/* | grep veth | xargs -I '{}' sudo ip link del {} &>/dev/null

echo "Cleanup complete."