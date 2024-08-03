#!/bin/bash

# This script must run as root user
# This will setup sonarqube and a database which is required for sonarqube. Then it will take some time to initalize.
# Then scrit will create a user project in sonarqube and generate token. Kindly store the token and project-key for future use 

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

# Function to display notification
display_notification() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    display_error "This script must be run as root."
fi

# Check if the value is already set
current_value=$(sysctl -n vm.max_map_count)

if [ "$current_value" -ne 262144 ]; then
    echo "Setting vm.max_map_count to 262144..."

    # Add or update the vm.max_map_count value in /etc/sysctl.conf
    if grep -q "vm.max_map_count" /etc/sysctl.conf; then
        sed -i 's/^vm.max_map_count.*/vm.max_map_count=262144/' /etc/sysctl.conf
    else
        echo "vm.max_map_count=262144" >> /etc/sysctl.conf
    fi

    # Apply the change
    sysctl -w vm.max_map_count=262144

    echo "vm.max_map_count has been set to 262144 and saved in /etc/sysctl.conf"
else
    echo "vm.max_map_count is already set to 262144"
fi

# Check if Docker Compose is installed, if not, install it
if ! command -v docker-compose &> /dev/null; then
    display_notification "Docker Compose not found, installing..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || display_error "Failed to download Docker Compose"
    chmod +x /usr/local/bin/docker-compose || display_error "Failed to make Docker Compose executable"
    docker-compose --version || display_error "Failed to verify Docker Compose installation"
else
    display_success "Docker Compose is already installed."
fi

# Ask the user where SonarQube-related files and folders need to be stored
read -p "Enter the directory where SonarQube-related files and folders should be stored (absolute path): " sonarqube_dir

# Create the necessary directories for SonarQube
display_notification "Creating necessary directories for SonarQube..."
mkdir -p "$sonarqube_dir/sonarqube_data" "$sonarqube_dir/sonarqube_extensions" "$sonarqube_dir/sonarqube_logs" "$sonarqube_dir/sonarqube_temp" || display_error "Failed to create directories"

# Set ownership and permissions for the directories
display_notification "Setting ownership and permissions for the directories..."
chown -R 1000:1000 "$sonarqube_dir/sonarqube_data" "$sonarqube_dir/sonarqube_extensions" "$sonarqube_dir/sonarqube_logs" "$sonarqube_dir/sonarqube_temp" || display_error "Failed to set ownership"
chmod -R 755 "$sonarqube_dir/sonarqube_data" "$sonarqube_dir/sonarqube_extensions" "$sonarqube_dir/sonarqube_logs" "$sonarqube_dir/sonarqube_temp" || display_error "Failed to set permissions"

# Create the Docker Compose file for SonarQube
display_notification "Creating the Docker Compose file for SonarQube..."
cat <<EOF > "$sonarqube_dir/docker-compose.yml"
version: '3.8'

services:
  sonarqube:
    image: sonarqube:lts-community
    depends_on:
      - sonar_db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://sonar_db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    ports:
      - "9001:9000"
    volumes:
      - sonarqube_conf:/opt/sonarqube/conf
      - $sonarqube_dir/sonarqube_data:/opt/sonarqube/data
      - $sonarqube_dir/sonarqube_extensions:/opt/sonarqube/extensions
      - $sonarqube_dir/sonarqube_logs:/opt/sonarqube/logs
      - $sonarqube_dir/sonarqube_temp:/opt/sonarqube/temp
    restart: always

  sonar_db:
    image: postgres:13
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - sonar_db:/var/lib/postgresql
      - sonar_db_data:/var/lib/postgresql/data
    restart: always

volumes:
  sonarqube_conf:
  sonar_db:
  sonar_db_data:
EOF

# Navigate to the SonarQube directory
display_notification "Navigating to the SonarQube directory..."
cd "$sonarqube_dir" || display_error "Failed to navigate to $sonarqube_dir"

# Start SonarQube using Docker Compose
display_notification "Starting SonarQube using Docker Compose..."
docker-compose up -d || display_error "Failed to start SonarQube"

# Notify the user
display_success "SonarQube will be available on port 9001. The username and default password will be admin."

# Wait for the initialization
display_notification "Waiting for SonarQube to initialize..."
sleep 60

# Create a SonarQube project using API
read -p "Enter the name for the new SonarQube project ( eg:cicd_project): " project_name
read -p "Enter the project key (alphanumeric and underscores only,eg:cicd_project ): " project_key

display_notification "Creating SonarQube project..."
response=$(curl -s -u admin:admin -X POST "http://localhost:9001/api/projects/create?name=$project_name&project=$project_key")

if echo "$response" | grep -q '"project"'; then
    display_success "Project $project_name created successfully."
else
    display_error "Failed to create project. Response: $response"
fi

# Generate a user token
read -p "Enter the token name: " token_name
display_notification "Generating user token..."
token_response=$(curl -s -u admin:admin -X POST "http://localhost:9001/api/user_tokens/generate?name=$token_name")

token=$(echo "$token_response" | grep -oP '(?<="token":")[^"]*')

if [ -n "$token" ]; then
    display_success "User token generated successfully."
    display_notification "Project Key: $project_key"
    display_notification "User Token: $token"
else
    display_error "Failed to generate user token. Response: $token_response"
fi

display_success "Initialization complete."
