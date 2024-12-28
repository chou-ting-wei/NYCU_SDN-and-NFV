#!/bin/bash
#set -x

# if [ "$EUID" -ne 0 ]
#   then log "Please run as root"
#   exit
# fi

# MTU Settings
WG_MTU=1420
OVS_MTU=1370

log() {
    echo "[`date '+%Y-%m-%d %H:%M:%S'`] $*"
}

# Creates a veth pair
# params: endpoint1 endpoint2
create_veth_pair() {
    local if1=$1
    local if2=$2
    log "Creating veth pair: $if1 <-> $if2"
    sudo ip link add "$if1" type veth peer name "$if2" || { log "Failed to create veth pair $if1 <-> $if2"; exit 1; }
    sudo ip link set "$if1" mtu "$OVS_MTU" || { log "Failed to set MTU for $if1"; exit 1; }
    sudo ip link set "$if2" mtu "$OVS_MTU" || { log "Failed to set MTU for $if2"; exit 1; }
    sudo ip link set "$if1" up || { log "Failed to bring up $if1"; exit 1; }
    sudo ip link set "$if2" up || { log "Failed to bring up $if2"; exit 1; }
    
    # Verify creation
    if ! sudo ip link show "$if1" &>/dev/null || ! sudo ip link show "$if2" &>/dev/null; then
        log "Veth interfaces $if1 or $if2 not found after creation."
        exit 1
    fi
    log "Veth pair $if1 <-> $if2 created successfully."
}

# Add a container with a certain image
# params: image_name container_name
add_container() {
    local image_name=$1
    local container_name=$2
    log "Adding container: $container_name using image: $image_name"
    sudo docker run -dit --network=none --privileged --cap-add NET_ADMIN --cap-add SYS_MODULE \
        --hostname "$container_name" --name "$container_name" "${@:3}" "$image_name" &>/dev/null || { log "Failed to add container $container_name"; exit 1; }
    
    local pid
    pid=$(sudo docker inspect -f '{{.State.Pid}}' "$container_name") || { log "Failed to get PID for container $container_name"; exit 1; }
    sudo mkdir -p /var/run/netns
    sudo ln -sf "/proc/$pid/ns/net" "/var/run/netns/$pid" || { log "Failed to link network namespace for container $container_name"; exit 1; }
    log "Container $container_name added successfully with PID $pid."
}

add_onos() {
    log "Adding ONOS container..."
    sudo docker run --name ONOS -d -p 2620:2620 -p 8181:8181 -p 6653:6653 -p 8101:8101 onosproject/onos:2.7-latest &>/dev/null || true
    local pid
    pid=$(sudo docker inspect -f '{{.State.Pid}}' ONOS) || { log "Failed to get PID for ONOS container"; exit 1; }
    sudo mkdir -p /var/run/netns
    sudo ln -sf "/proc/$pid/ns/net" "/var/run/netns/$pid" || { log "Failed to link network namespace for ONOS"; exit 1; }

    until sudo docker exec ONOS /bin/bash -c "curl -s http://localhost:8181/onos/v1/system/cluster/nodes" &>/dev/null; do
        log "Waiting for ONOS to start..."
        sleep 1
    done
    log "ONOS started successfully."

    log "Updating package lists in ONOS container..."
    sudo docker exec ONOS /bin/bash -c "apt-get update &>/dev/null" || { log "Failed to update package lists in ONOS container"; exit 1; }
    log "Package lists updated successfully."

    log "Installing necessary packages in ONOS container..."
    sudo docker exec ONOS /bin/bash -c "apt-get install -y sshpass iproute2 tcpdump mtr iputils-ping net-tools &>/dev/null" || { log "Failed to install packages in ONOS container"; exit 1; }
    log "Necessary packages installed successfully."

    log "Generating SSH key in ONOS container..."
    sudo docker exec ONOS /bin/bash -c "ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa <<< '' >/dev/null 2>&1" || { log "Failed to generate SSH key in ONOS container"; exit 1; }
    log "SSH key generated successfully."

    log "Activating required ONOS applications..."
    sudo docker exec ONOS /bin/bash -c "
        sshpass -p 'karaf' ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost '
            app activate org.onosproject.drivers;
            app activate org.onosproject.fpm;
            app activate org.onosproject.gui2;
            app activate org.onosproject.hostprovider;
            app activate org.onosproject.lldpprovider;
            app activate org.onosproject.openflow;
            app activate org.onosproject.openflow-base;
            app activate org.onosproject.optical-model;
            app activate org.onosproject.route-service;
        '
    " || { log "Failed to activate ONOS applications"; exit 1; }
    log "ONOS applications activated successfully."
}
# app activate org.onosproject.fwd;
# Set container interface's ip address and gateway
# params: container_name infname [ipaddress] [gw addr]
set_intf_container() {
    local container=$1
    local ifname=$2
    local ipaddr=$3
    local gw_addr=${4:-}
    log "Configuring interface $ifname for container $container with IP $ipaddr"
    
    local pid
    pid=$(sudo docker inspect -f '{{.State.Pid}}' "$container") || { log "Failed to get PID for container $container"; exit 1; }

    sudo ip link set "$ifname" netns "$pid" || { log "Failed to set $ifname to netns $pid"; exit 1; }
    sudo ip netns exec "$pid" ip addr add "$ipaddr" dev "$ifname" || { log "Failed to add IP $ipaddr to $ifname in container $container"; exit 1; }
    sudo ip netns exec "$pid" ip link set "$ifname" up || { log "Failed to bring up $ifname in container $container"; exit 1; }
    sudo ip netns exec "$pid" ip link set "$ifname" mtu "$OVS_MTU" || { log "Failed to set MTU for $ifname in container $container"; exit 1; }
    
    if [ -n "$gw_addr" ]; then
        sudo ip netns exec "$pid" ip route add default via "$gw_addr" || { log "Failed to add default route in container $container"; exit 1; }
    fi
    log "Interface $ifname configured successfully in container $container."
}

# Set container interface's ipv6 address and gateway
# params: container_name infname [ipaddress] [gw addr]
set_v6intf_container() {
    local container=$1
    local ifname=$2
    local ipaddr=$3
    local gw_addr=${4:-}
    log "Configuring IPv6 interface $ifname for container $container with IP $ipaddr"
    
    local pid
    pid=$(sudo docker inspect -f '{{.State.Pid}}' "$container") || { log "Failed to get PID for container $container"; exit 1; }

    # sudo ip link set "$ifname" netns "$pid" || { log "Failed to set $ifname to netns $pid"; exit 1; }
    sudo ip netns exec "$pid" ip -6 addr add "$ipaddr" dev "$ifname" || { log "Failed to add IPv6 $ipaddr to $ifname in container $container"; exit 1; }
    sudo ip netns exec "$pid" ip link set "$ifname" up || { log "Failed to bring up $ifname in container $container"; exit 1; }
    sudo ip netns exec "$pid" ip link set "$ifname" mtu "$OVS_MTU" || { log "Failed to set MTU for $ifname in container $container"; exit 1; }
    
    if [ -n "$gw_addr" ]; then
        sudo ip netns exec "$pid" ip -6 route add default via "$gw_addr" || { log "Failed to add IPv6 default route in container $container"; exit 1; }
    fi
    log "IPv6 interface $ifname configured successfully in container $container."
}

# Connects the bridge and the container
# params: bridge_name container_name [ipaddress] [ipv6address] [gw addr] [ipv6gw addr]
build_bridge_container_path() {
    local bridge=$1
    local container=$2
    local ipaddr=${3:-}
    local ip6addr=${4:-}
    local gw_addr=${5:-}
    local ip6gw_addr=${6:-}

    local br_inf="veth${bridge}${container}"
    local container_inf="veth${container}${bridge}"
    
    create_veth_pair "$br_inf" "$container_inf"
    sudo ovs-vsctl add-port "$bridge" "$br_inf" || { log "Failed to add port $br_inf to bridge $bridge"; exit 1; }
    
    if [ -n "$ipaddr" ]; then
        set_intf_container "$container" "$container_inf" "$ipaddr" "$gw_addr"
    fi
    
    if [ -n "$ip6addr" ]; then
        set_v6intf_container "$container" "$container_inf" "$ip6addr" "$ip6gw_addr"
    fi
}

# Connects two ovsswitches
# params: ovs1 ovs2
build_ovs_path() {
    local ovs1=$1
    local ovs2=$2
    local inf1="veth${ovs1}${ovs2}"
    local inf2="veth${ovs2}${ovs1}"
    
    create_veth_pair "$inf1" "$inf2"
    sudo ovs-vsctl add-port "$ovs1" "$inf1" || { log "Failed to add port $inf1 to bridge $ovs1"; exit 1; }
    sudo ovs-vsctl add-port "$ovs2" "$inf2" || { log "Failed to add port $inf2 to bridge $ovs2"; exit 1; }
}

# Connects a container to an ovsswitch
# params: ovs container [ipaddress] [ipv6address] [gw addr] [ipv6gw addr]
build_ovs_container_path() {
    local ovs_bridge=$1
    local container=$2
    local ipaddr=${3:-}
    local ip6addr=${4:-}
    local gw_addr=${5:-}
    local ip6gw_addr=${6:-}

    local ovs_inf="veth${ovs_bridge}${container}"
    local container_inf="veth${container}${ovs_bridge}"
    
    create_veth_pair "$ovs_inf" "$container_inf"
    sudo ovs-vsctl add-port "$ovs_bridge" "$ovs_inf" || { log "Failed to add port $ovs_inf to bridge $ovs_bridge"; exit 1; }
    
    if [ -n "$ipaddr" ]; then
        set_intf_container "$container" "$container_inf" "$ipaddr" "$gw_addr"
    fi
    
    if [ -n "$ip6addr" ]; then
        set_v6intf_container "$container" "$container_inf" "$ip6addr" "$ip6gw_addr"
    fi
}

HOSTIMAGE="sdnfv-final-host"
ROUTERIMAGE="sdnfv-final-frr"
BASEDIR=$(dirname "$0")
ID="43"
PEERID1="44"
PEERID2="45"

# Build host base image
log "Building Docker images..."
sudo docker build containers/host -t "$HOSTIMAGE" || { log "Failed to build $HOSTIMAGE"; exit 1; }
sudo docker build containers/frr -t "$ROUTERIMAGE" || { log "Failed to build $ROUTERIMAGE"; exit 1; }
log "Docker images built successfully."

# TODO Write your own code
add_onos

add_container "$HOSTIMAGE" h01
add_container "$HOSTIMAGE" h02
add_container "$ROUTERIMAGE" speaker -v "$(realpath "$BASEDIR/config/daemons")":/etc/frr/daemons -v "$(realpath "$BASEDIR/config/$ID/speaker/frr.conf")":/etc/frr/frr.conf
add_container "$ROUTERIMAGE" er01 -v "$(realpath "$BASEDIR/config/daemons")":/etc/frr/daemons -v "$(realpath "$BASEDIR/config/$ID/er01/frr.conf")":/etc/frr/frr.conf

log "Creating OVS bridges..."
sudo ovs-vsctl add-br ovs1 -- set bridge ovs1 other_config:datapath-id=000000000000${ID}01 other_config:lldp=true -- set bridge ovs1 protocols=OpenFlow14 -- set-controller ovs1 tcp:127.0.0.1:6653 || { log "Failed to create ovs1"; exit 1; }
sudo ovs-vsctl add-br ovs2 -- set bridge ovs2 other_config:datapath-id=000000000000${ID}02 other_config:lldp=true -- set bridge ovs2 protocols=OpenFlow14 -- set-controller ovs2 tcp:127.0.0.1:6653 || { log "Failed to create ovs2"; exit 1; }
sudo ovs-vsctl add-port ovs2 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=192.168.60.$ID mtu_request=$OVS_MTU || { log "Failed to add vxlan0 to ovs2"; exit 1; }
sudo ovs-vsctl add-port ovs2 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=192.168.61.$PEERID1 mtu_request=$OVS_MTU || { log "Failed to add vxlan1 to ovs2"; exit 1; }
sudo ovs-vsctl add-port ovs2 vxlan2 -- set interface vxlan2 type=vxlan options:remote_ip=192.168.61.$PEERID2 mtu_request=$OVS_MTU || { log "Failed to add vxlan2 to ovs2"; exit 1; }

log "Configuring OVS bridges..."
sudo ip link set ovs1 mtu "$OVS_MTU" || { log "Failed to set MTU for ovs1"; exit 1; }
sudo ip link set ovs2 mtu "$OVS_MTU" || { log "Failed to set MTU for ovs2"; exit 1; }
sudo ip link set ovs1 up || { log "Failed to bring up ovs1"; exit 1; }
sudo ip link set ovs2 up || { log "Failed to bring up ovs2"; exit 1; }
log "OVS bridges configured successfully."

# 65xx0
log "Connecting OVS bridges..."
build_ovs_path ovs1 ovs2
log "OVS bridges connected successfully."

log "Connecting OVS bridges to containers..."
build_ovs_container_path ovs2 h01 172.16.$ID.2/24 2a0b:4e07:c4:$ID::2/64 172.16.$ID.1 2a0b:4e07:c4:$ID::1
sudo docker exec -it h01 ip link set vethh01ovs2 address 02:42:ac:11:01:$ID || { log "Failed to set MAC address on h01"; exit 1; }
build_ovs_container_path ovs1 speaker 192.168.70.$ID/24 fd70::$ID/64 
# build_ovs_container_path ovs1 speaker 172.16.$ID.69/24 2a0b:4e07:c4:$ID::69/64 172.16.$ID.1 2a0b:4e07:c4:$ID::1
log "OVS bridges connected to containers successfully."

log "Creating OVS bridge bre1..."
sudo ovs-vsctl add-br bre1 || { log "Failed to create bre1"; exit 1; }
sudo ip link set bre1 mtu "$OVS_MTU" || { log "Failed to set MTU for bre1"; exit 1; }
sudo ip link set bre1 up || { log "Failed to bring up bre1"; exit 1; }
log "OVS bridge bre1 created and configured successfully."

# 65xx1
log "Connecting bre1 to containers..."
build_bridge_container_path bre1 h02 172.17.$ID.2/24 2a0b:4e07:c4:1$ID::2/64 172.17.$ID.1 2a0b:4e07:c4:1$ID::1
build_bridge_container_path bre1 er01 172.17.$ID.1/24 2a0b:4e07:c4:1$ID::1/64
log "bre1 connected to containers successfully."

log "Connecting ovs1 to er01..."
build_ovs_container_path ovs1 er01 192.168.63.2/24 fd63::2/64
sudo docker exec -it er01 ip link set vether01ovs1 address 02:42:ac:11:02:$ID || { log "Failed to set MAC address on er01"; exit 1; }
log "ovs1 connected to er01 successfully."

# speaker
log "Configuring speaker container..."
create_veth_pair vethhostspeaker vethspeakerhost
# sudo ip addr add 192.168.100.1/24 dev vethhostspeaker || { log "Failed to add IP to vethhostspeaker"; exit 1; }
# sudo ovs-vsctl add-port ovs1 vethhostspeaker || { log "Failed to add vethhostspeaker to ovs1"; exit 1; }
set_intf_container ONOS vethhostspeaker 192.168.100.1/24
set_intf_container speaker vethspeakerhost 192.168.100.3/24

log "Assigning additional IPs to speaker's interfaces..."
sudo docker exec -it speaker ip link set vethspeakerovs1 address 02:42:ac:11:00:$ID || { log "Failed to set MAC address on speaker"; exit 1; }
sudo docker exec -it speaker ip addr add 192.168.63.1/24 dev vethspeakerovs1 || { log "Failed to add IP to speaker's veth"; exit 1; }
# sudo docker exec -it speaker ip addr add 192.168.70.$ID/24 dev vethspeakerovs1 || { log "Failed to add second IP to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip addr add 172.16.$ID.69/24 dev vethspeakerovs1 || { log "Failed to add third IP to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip -6 addr add fd63::1/64 dev vethspeakerovs1 || { log "Failed to add IPv6 to speaker's veth"; exit 1; }
# sudo docker exec -it speaker ip -6 addr add fd70::$ID/64 dev vethspeakerovs1 || { log "Failed to add second IPv6 to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip -6 addr add 2a0b:4e07:c4:$ID::69/64 dev vethspeakerovs1 || { log "Failed to add third IPv6 to speaker's veth"; exit 1; }

sudo docker exec -it speaker ip addr add 192.168.$PEERID2.$ID/24 dev vethspeakerovs1 || { log "Failed to add IP to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip -6 addr add fd$PEERID2::$ID/64 dev vethspeakerovs1 || { log "Failed to add IPv6 to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip addr add 192.168.$PEERID1.$ID/24 dev vethspeakerovs1 || { log "Failed to add IP to speaker's veth"; exit 1; }
sudo docker exec -it speaker ip -6 addr add fd$PEERID1::$ID/64 dev vethspeakerovs1 || { log "Failed to add IPv6 to speaker's veth"; exit 1; }

log "Speaker container configured successfully."

sudo docker exec -it er01 sysctl -w net.ipv6.conf.all.forwarding=1

onos-netcfg localhost $BASEDIR/config/$ID/config.json

onos-app localhost install! target/ProxyArp-1.0-SNAPSHOT.oar
onos-app localhost install! target/bridge-app-1.0-SNAPSHOT.oar
onos-app localhost install! target/vrouter-1.0-SNAPSHOT.oar

log "Setup complete."

chmod +x $BASEDIR/config/$ID/flow.sh
bash $BASEDIR/config/$ID/flow.sh