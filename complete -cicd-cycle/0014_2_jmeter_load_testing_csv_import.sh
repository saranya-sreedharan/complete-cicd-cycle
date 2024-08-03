#!/bin/bash

# Database connection parameters
DB_NAME="api_test_reports"
DB_USER="sonar"
DB_PASSWORD="sonar"
DB_HOST="f69de104b906"
DB_PORT="5432"
CSV_FILE="/var/jenkins_home/workspace/cicd-project/jmeter_folder/csv/wikipedia.csv"

# Create the table
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME <<EOF
DROP TABLE IF EXISTS jmeter_results;
CREATE TABLE jmeter_results (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP NOT NULL,
    elapsed INTEGER NOT NULL,
    label VARCHAR(255) NOT NULL,
    responseCode VARCHAR(10) NOT NULL,
    responseMessage TEXT,
    threadName VARCHAR(255),
    dataType VARCHAR(10),
    success BOOLEAN NOT NULL,
    failureMessage TEXT,
    bytes INTEGER,
    sentBytes INTEGER,
    grpThreads INTEGER,
    allThreads INTEGER,
    url VARCHAR(255),
    latency INTEGER,
    idleTime INTEGER,
    connectTime INTEGER
);
EOF

# Read the CSV file and import data into PostgreSQL
while IFS=, read -r timestamp elapsed label responseCode responseMessage threadName dataType success failureMessage bytes sentBytes grpThreads allThreads url latency idleTime connectTime; do
    if [[ $timestamp != "timeStamp" ]]; then
        PSQL="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
        # Convert timestamp from milliseconds to seconds
        timestamp=$(($timestamp / 1000))
        SQL="INSERT INTO jmeter_results (timestamp, elapsed, label, responseCode, responseMessage, threadName, dataType, success, failureMessage, bytes, sentBytes, grpThreads, allThreads, url, latency, idleTime, connectTime) VALUES (to_timestamp($timestamp), $elapsed, '$label', '$responseCode', '$responseMessage', '$threadName', '$dataType', $success, '$failureMessage', $bytes, $sentBytes, $grpThreads, $allThreads, '$url', $latency, $idleTime, $connectTime);"
        echo "$SQL" | PGPASSWORD=$DB_PASSWORD $PSQL
    fi
done < "$CSV_FILE"