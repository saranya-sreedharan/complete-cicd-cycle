#!/bin/bash

# Colors for formatting
RED='\033[0;31m'    # Red colored text
GREEN='\033[0;32m'  # Green colored text
YELLOW='\033[1;33m' # Yellow colored text
NC='\033[0m'        # Normal text

# Function to display error message and exit
display_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display success message
display_success() {
    echo -e "${GREEN}$1${NC}"
}

echo -e "${YELLOW}Setting up PostgreSQL Exporter...${NC}"

# Prompt user for PostgreSQL credentials
read -p "Enter PostgreSQL username: " pg_username
read -sp "Enter PostgreSQL password: " pg_password
echo
read -p "Enter PostgreSQL database name: " pg_database
read -p "Enter PostgreSQL host (default: localhost): " pg_host
pg_host=${pg_host:-localhost}

# Define Docker Compose file path
docker_compose_file="/home/operators/rough_work/docker-compose.yml"

# Create Docker Compose file
sudo tee $docker_compose_file > /dev/null <<EOF
version: '3.8'

services:
  postgres_exporter:
    image: wrouesnel/postgres_exporter:latest
    environment:
      - DATA_SOURCE_NAME=postgresql://$pg_username:$pg_password@$pg_host:5432/$pg_database?sslmode=disable
    ports:
      - "9187:9187"
    restart: always
EOF

# Start PostgreSQL Exporter service using Docker Compose
sudo docker-compose -f $docker_compose_file up -d || display_error "Failed to start PostgreSQL Exporter using Docker Compose."

display_success "PostgreSQL Exporter setup completed successfully. The exporter is running on port 9187."
