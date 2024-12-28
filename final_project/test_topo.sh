#!/bin/bash

# docker exec ONOS /bin/bash -c "
#     sshpass -p 'karaf' ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost '
#         app activate org.onosproject.fwd
#     '
# "

docker exec ONOS /bin/bash -c "
sshpass -p 'karaf' ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost 'apps -a -s'
"
# docker exec ONOS /bin/bash -c "
# sshpass -p 'karaf' ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost 'flows -s'
# "
docker exec ONOS /bin/bash -c "
sshpass -p 'karaf' ssh -o StrictHostKeyChecking=no -p 8101 karaf@localhost 'routes'
"
