#!/bin/bash

# Import Temperatur
get_temperature() {
    SERVER_IP="172.16.17.160"
    DATA_URL="http://${SERVER_IP}/log/data_temp.txt"
    LOCAL_FILE="data_temp.txt"

    curl -s ${DATA_URL} > ${LOCAL_FILE}

    if [[ -f ${LOCAL_FILE} ]]; then
        last_entry=$(tail -n 1 ${LOCAL_FILE})
        temperature=$(echo ${last_entry} | awk -F, '{print $2}')
        echo "${temperature}"
        rm ${LOCAL_FILE}
    else
        echo "Error: Temperature data file not found on the server"
    fi
}

# Subject
subject="Server temperature alert"

# Temperature Limits
min_temperature=10
max_temperature=20

while true; do
    # Get current temperature
    current_temperature=$(get_temperature)

    # Display current temperature in the terminal
    echo "Current temperature: ${current_temperature} °C"

    # Body
    if (( $(echo "$current_temperature < $min_temperature" | bc -l) )) || (( $(echo "$current_temperature > $max_temperature" | bc -l) )); then
        body="Die Temperatur vom Server m122-server.local ist aktuell auf $current_temperature Grad, welches ausserhalb des akzeptablen Bereichs von $min_temperature bis $max_temperature liegt und somit als nicht konform eingestuft ist"
        
        # Sending the Message
        mail -s "$subject" -a "From:HM<bashlb2@smart-mail.de>" nedin.havzija@edu.tbz.ch <<< "$body"
    fi

    # Sleep for 30 seconds
    sleep 30
done

