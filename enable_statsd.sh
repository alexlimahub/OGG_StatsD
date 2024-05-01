#!/bin/bash

deployment_name="WEST"
deployment_port=1055


# Stop Deployment
curl -k -u oggadmin:"Welcome##123" \
-d '{"status": "stopped","enabled": false}' \
-X PATCH https://localhost:${deployment_port}/services/v2/deployments/${deployment_name}

echo

# Enable StatsD
cmd="docker exec -it ogg234demo /bin/bash -c \"curl -svu oggadmin:\\\"Welcome##123\\\" http://172.13.0.101:9011/services/v2/deployments/\\\"${deployment_name}\\\" -X PATCH --data '{\\\"metrics\\\": {\\\"enabled\\\":true, \\\"servers\\\": [ {\\\"type\\\":\\\"pmsrvr\\\", \\\"protocol\\\":\\\"uds\\\"}, {\\\"type\\\":\\\"statsd\\\", \\\"host\\\":\\\"172.13.0.200\\\"}]}}'\""
eval $cmd

echo

# Starts Deployment
curl -k -u oggadmin:"Welcome##123" \
-d '{"status": "running","enabled": true}' \
-X PATCH https://localhost:${deployment_port}/services/v2/deployments/${deployment_name}

echo
echo #########
