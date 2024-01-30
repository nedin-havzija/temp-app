#!/bin/bash
 
# Autor: Nedin Havzija
# Datum: 23.01.2024
# Version: 1.2
# Beschreibung:
# Bash-Skript, das Daten vom Server m122-server.local oder kel.internet-box.ch:2206 abruft und anschließend anzeigt. Wenn die Temperaturen über 20 °C steigen,
# oder unter 10 °C fallen, wird eine E-Mail-Warnung versendet und die Information wird auch auf dem DB-Server gespeichert.
# Zusätzlich wird eine Benachrichtigung gesendet, falls die Datenbank nicht erreichbar ist.
 
 
SERVER_IP="172.16.17.160"
DATA_URL="http://${SERVER_IP}/log/data_temp.txt"
LOCAL_FILE="data_temp.txt"
db_user="user01"
db_pass="MaSq-01"
db_host="172.16.17.160"
db_name="temperature-app-nedval"
db_table_name="temperature"
place="TBZ_Schulzimmer"
 
while true; do
    # Fetch the file from the server using curl
    curl -s ${DATA_URL} > ${LOCAL_FILE}
 
    if [[ -f ${LOCAL_FILE} ]]; then
        # Extract the last temperature entry from the file
        last_entry=$(tail -n 1 ${LOCAL_FILE})
        # Extract temperature value from the last entry
        temperature=$(echo ${last_entry} | awk -F, '{print $2}')
        echo "Current temperature: ${temperature} °C"
        # Check for temperature warnings
        if (( $(echo "${temperature} > 20" | bc -l) )); then
            echo "Warning: Too hot! Temperature exceeds 20 degrees."
            # Sending email
            subject="Temperature Warning: Too Hot!"
            body="Warning: The temperature in ${place} is currently ${temperature} degrees, which exceeds the limit of 20 degrees."
            mail -s "$subject" -a From:HM\<lbtest2@smart-mail.de\> nedin.havzija@edu.tbz.ch <<< "$body"
            # Execute SQL query for the warning if the SQL server is available
            if mysql -h $db_host -u $db_user -p$db_pass -e "SHOW DATABASES;" &> /dev/null; then
                timestamp=$(date +"%Y-%m-%d %H:%M:%S")
                sql="INSERT INTO ${db_table_name} (timestamp, temperature, place) VALUES ('${timestamp}', '${temperature}', '${place}')"
                mysql -h $db_host -u $db_user -p$db_pass $db_name -e "$sql"
            else
                # Sending email for SQL server unavailability
                subject="SQL Server Unavailable!"
                body="Warning: Unable to connect to the SQL server at ${db_host}. Temperature data could not be recorded."
                mail -s "$subject" -a From:HM\<lbtest2@smart-mail.de\> nedin.havzija@edu.tbz.ch <<< "$body"
            fi
        elif (( $(echo "${temperature} < 10" | bc -l) )); then
            echo "Warning: Too cold! Temperature is below 10 degrees."
            # Sending email
            subject="Temperature Warning: Too Cold!"
            body="Warning: The temperature in ${place} is currently ${temperature} degrees, which is below the limit of 10 degrees."
            mail -s "$subject" -a From:HM\<lbtest2@smart-mail.de\> nedin.havzija@edu.tbz.ch <<< "$body"
            # Execute SQL query for the warning if the SQL server is available
            if mysql -h $db_host -u $db_user -p$db_pass -e "SHOW DATABASES;" &> /dev/null; then
                timestamp=$(date +"%Y-%m-%d %H:%M:%S")
                sql="INSERT INTO ${db_table_name} (timestamp, temperature, place) VALUES ('${timestamp}', '${temperature}', '${place}')"
                mysql -h $db_host -u $db_user -p$db_pass $db_name -e "$sql"
            else
                # Sending email for SQL server unavailability
                subject="SQL Server Unavailable!"
                body="Warning: Unable to connect to the SQL server at ${db_host}. Temperature data could not be recorded."
                mail -s "$subject" -a From:HM\<lbtest2@smart-mail.de\> nedin.havzija@edu.tbz.ch <<< "$body"
            fi
        fi
 
        # Remove the temporary local copy
        rm ${LOCAL_FILE}
    else
        echo "Error: Temperature data file not found on the server"
        # Sleep for 300 seconds (5 minutes) even if there's an error
        sleep 300
        continue
    fi
 
    # Sleep for 300 seconds (5 minutes)
    sleep 300
done
