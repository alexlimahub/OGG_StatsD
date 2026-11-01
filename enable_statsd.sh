#!/bin/bash
# Enables GoldenGate metrics (StatsD push to Telegraf) on the deployment and
# restarts any existing Extracts/Replicats so they start reporting.

deployment_name="WEST"
ogg_auth='oggadmin:Welcome##123'
ogg_api="https://${OGG_HOST:-localhost}:${OGG_PORT:-1055}/services/v2"
# Admin Service URL, reachable from inside the Docker network only
admin_url="http://172.28.0.101:9011/services/v2/deployments/${deployment_name}"
statsd_host="172.28.0.200"   # DOCKER_TELEGRAF_IP in .env

# Wait until the deployment reports the given status (running|stopped)
wait_for_deployment() {
    for i in $(seq 1 60); do
        status=$(curl -sk -u "$ogg_auth" "$ogg_api/deployments/$deployment_name" | grep -o '"status":"[a-z]*"' | head -1 | cut -d'"' -f4)
        [ "$status" = "$1" ] && return 0
        sleep 5
    done
    echo "Timed out waiting for deployment $deployment_name to be $1"
    exit 1
}

# Skip if StatsD is already enabled (makes the script safe to re-run)
if curl -sk -u "$ogg_auth" "$ogg_api/deployments/$deployment_name" | grep -q '"type":"statsd"'; then
    echo "StatsD metrics already enabled, nothing to do."
    exit 0
fi

# Stop Deployment
curl -sk -u "$ogg_auth" \
-d '{"status": "stopped","enabled": false}' \
-X PATCH "$ogg_api/deployments/${deployment_name}"
echo
wait_for_deployment stopped

# Enable StatsD
# From the host this goes through the GoldenGate container; inside the network
# (compose "setup" service) it calls the Admin Service directly.
if command -v docker > /dev/null; then
    admin_curl=(docker exec -i ogg234demo curl)
else
    admin_curl=(curl)
fi
"${admin_curl[@]}" -su "$ogg_auth" "$admin_url" -X PATCH \
--data '{"metrics": {"enabled":true, "servers": [ {"type":"pmsrvr", "protocol":"uds"}, {"type":"statsd", "host":"'$statsd_host'"}]}}'
echo

# Start Deployment
curl -sk -u "$ogg_auth" \
-d '{"status": "running","enabled": true}' \
-X PATCH "$ogg_api/deployments/${deployment_name}"
echo
wait_for_deployment running

# Restart Extracts and Replicats so they pick up the metrics configuration
sleep 10
for type in extracts replicats; do
    for name in $(curl -sk -u "$ogg_auth" "$ogg_api/$type" | grep -o '"name":"[A-Z0-9_]*"' | cut -d'"' -f4); do
        echo "Restarting $name ......"
        curl -sk -u "$ogg_auth" -X PATCH "$ogg_api/$type/$name" -d '{"status":"stopped"}' > /dev/null
        for i in $(seq 1 30); do
            curl -sk -u "$ogg_auth" "$ogg_api/$type/$name/info/status" | grep -q '"status":"stopped"' && break
            sleep 2
        done
        curl -sk -u "$ogg_auth" -X PATCH "$ogg_api/$type/$name" -d '{"status":"running"}' > /dev/null
    done
done

echo
echo "#########################################################################"
echo "# Metrics enabled. Dashboards: http://localhost:3000 (Main Dashboard)   #"
echo "#########################################################################"
