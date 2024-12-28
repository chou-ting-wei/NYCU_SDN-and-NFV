#For ARP
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"3\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"2\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"3\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"4\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"3\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                },
                {
                    \"type\": \"ETH_DST\",
                    \"mac\": \"02:42:ac:11:00:43\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"FLOOD\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"4\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"5\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                },
                {
                    \"type\": \"ETH_DST\",
                    \"mac\": \"02:42:ac:11:00:43\"
                }
            ]
        }
    }'
"
sleep 0.1

docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"5\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0806\"
                }
            ]
        }
    }'
"
sleep 0.1

# FOR NDP

sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"3\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"2\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"3\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"4\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"3\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004301 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004301\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"FLOOD\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1
docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"4\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"5\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"1\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1

docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:0000000000004302 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:0000000000004302\",
        \"treatment\": {
            \"instructions\": [
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"CONTROLLER\"
                },
                {
                    \"type\": \"OUTPUT\",
                    \"port\": \"1\"
                }
            ]
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"IN_PORT\",
                    \"port\": \"5\"
                },
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 58
                },
                {
                    \"type\": \"ICMPV6_TYPE\",
                    \"icmpv6Type\": 135
                }
            ]
        }
    }'
"
sleep 0.1



docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": []
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x86DD\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 17
                },
                {
                    \"type\": \"UDP_DST\",
                    \"udpPort\": 5353
                },
                {
                    \"type\": \"IPV6_DST\",
                    \"ip\": \"ff02::fb/128\"
                }
            ]
        }
    }'
"
sleep 0.1

docker exec ONOS /bin/bash -c "
    curl -u karaf:karaf -X POST http://localhost:8181/onos/v1/flows/of:00005a654246eb49 -H 'Content-Type: application/json' -d '{
        \"priority\": 50000,
        \"timeout\": 0,
        \"isPermanent\": true,
        \"deviceId\": \"of:00005a654246eb49\",
        \"treatment\": {
            \"instructions\": []
        },
        \"selector\": {
            \"criteria\": [
                {
                    \"type\": \"ETH_TYPE\",
                    \"ethType\": \"0x0800\"
                },
                {
                    \"type\": \"IP_PROTO\",
                    \"protocol\": 17
                },
                {
                    \"type\": \"UDP_DST\",
                    \"udpPort\": 5353
                },
                {
                    \"type\": \"IPV4_DST\",
                    \"ip\": \"224.0.0.251/32\"
                }
            ]
        }
    }'
"
sleep 0.1