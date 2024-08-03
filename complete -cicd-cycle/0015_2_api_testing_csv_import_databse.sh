#!/bin/bash

# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST="api-test-sonar_db-1"
DB_PORT="5432"
DB_USER="sonar"
DB_NAME="api_test_reports"
CSV_FILE="/var/jenkins_home/workspace/cicd-project/newman/api_test_results.csv"
DB_PASSWORD="sonar"

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Create table if it doesn't exist
echo -e "${YELLOW}Creating table if not exists...${NC}"
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF
CREATE TABLE IF NOT EXISTS api_test_results_csv (
    iteration INTEGER,
    collectionName TEXT,
    requestName TEXT,
    method TEXT,
    url TEXT,
    status TEXT,
    code INTEGER,
    responseTime INTEGER,
    responseSize INTEGER,
    executed BOOLEAN,
    failed BOOLEAN,
    skipped BOOLEAN,
    totalAssertions INTEGER,
    executedCount INTEGER,
    failedCount INTEGER,
    skippedCount INTEGER
);
EOF
if [ $? -ne 0 ]; then
    handle_error "Failed to create table"
fi

# Import CSV data into the table
echo -e "${YELLOW}Importing CSV data into the table...${NC}"
PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF
\copy api_test_results_csv ( iteration, collectionName, requestName, method, url, status, code, responseTime, responseSize, executed, failed, skipped, totalAssertions, executedCount, failedCount, skippedCount) FROM '$CSV_FILE' DELIMITER ',' CSV HEADER;
EOF
if [ $? -ne 0 ]; then
    handle_error "Failed to import CSV data"
fi

echo -e "${YELLOW}CSV data successfully imported into the table.${NC}"