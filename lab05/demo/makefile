main:
	docker compose up -d
	sudo ovs-vsctl add-br ovsbr
	sudo ovs-vsctl set bridge ovsbr protocols=OpenFlow14
	sudo ovs-vsctl set-controller ovsbr tcp:127.0.0.1:6653
	sudo ovs-docker add-port ovsbr1 eth2 R1 --ipaddress=172.18.0.2/16
	sudo ovs-docker add-port ovsbr1 eth2 h1 --ipaddress=172.18.0.3/16
	sudo ovs-docker add-port ovsbr2 eth2 R2 --ipaddress=172.19.0.2/16
	sudo ovs-docker add-port ovsbr2 eth2 h2 --ipaddress=172.19.0.3/16
clean:
	docker compose down
	sudo ovs-vsctl del-br ovsbr