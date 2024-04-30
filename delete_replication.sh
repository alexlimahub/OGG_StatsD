#!/bin/bash

conn_propeties=("WEST:172.13.0.102" "EAST:172.13.0.103")
list_region=("WEST" "EAST")
ogg_port=281

curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/extracts/EWEST' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' 

curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/extracts/EEAST' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz'     

 curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/replicats/RWEST' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' 

curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/replicats/REAST' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz'        

# Add Schematranda, heartbeat and checkpoint tables to all Databases
for region in "${list_region[@]}"
do
    curl -k -X POST 'https://localhost:'${ogg_port}'/services/v2/connections/OracleGoldenGate.'$region'/trandata/schema' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' \
    -d '{"operation":"delete","schemaName":"hr"}'
    echo
    echo
    curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/connections/OracleGoldenGate.'$region'/tables/heartbeat' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' 
    echo
    echo
    curl -k -X POST 'https://localhost:'${ogg_port}'/services/v2/connections/OracleGoldenGate.'$region'/tables/checkpoint' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' \
    -d '{"operation":"delete","name":"oggadmin.checkpoints"}'
    echo
    echo
done

#Create Connection to the all Databases
for region in "${conn_propeties[@]}"
do
    conn_name=`echo $region | awk -F':' '{print $1}'`
    ip=`echo $region | awk -F':' '{print $2}'`
    curl -k -X DELETE 'https://localhost:'${ogg_port}'/services/v2/credentials/OracleGoldenGate/'$conn_name'' \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H 'Authorization: Basic b2dnYWRtaW46V2VsY29tZSMjMTIz' 
    echo 
    echo
done


echo
echo

