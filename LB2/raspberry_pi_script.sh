#!/bin/bash

SERVER_IP="172.16.17.160"
DATA_URL="http://${SERVER_IP}/log/data_temp.txt"
LOCAL_FILE="data_temp.txt"

while true; do
    # Fetch the file from the server using curl
    curl -s ${DATA_URL} > ${LOCAL_FILE}

    if [[ -f ${LOCAL_FILE} ]]; then
        # Extract the last temperature entry from the file
        last_entry=$(tail -n 1 ${LOCAL_FILE})
        
        # Extract temperature value from the last entry
        temperature=$(echo ${last_entry} | awk -F, '{print $2}')
        
        echo "Current temperature: ${temperature} °C"
        
        # Remove the temporary local copy
        rm ${LOCAL_FILE}
    else
        echo "Error: Temperature data file not found on the server"
    fi

# Sleep for 30 seconds
    sleep 30

done

