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

# Function to display notification
display_notification() {
    echo -e "${YELLOW}$1${NC}"
}

# Stop and remove Docker containers and volumes
display_notification "Reverting SonarQube setup..."

read -p "Enter the directory where SonarQube-related files and folders were stored (absolute path): " sonarqube_dir

# Check if the directory exists
if [ ! -d "$sonarqube_dir" ]; then
    display_error "Directory $sonarqube_dir does not exist."
fi

# Navigate to the SonarQube directory
display_notification "Navigating to $sonarqube_dir..."
cd "$sonarqube_dir" || display_error "Failed to navigate to $sonarqube_dir"

# Stop Docker Compose services
display_notification "Stopping Docker Compose services..."
docker-compose down || display_error "Failed to stop Docker Compose services"

# Remove Docker volumes
display_notification "Removing Docker volumes..."
docker volume rm $(docker volume ls -qf dangling=true) || display_error "Failed to remove Docker volumes"

# Remove the created directories and their contents
display_notification "Removing SonarQube-related directories and files..."
rm -rf "$sonarqube_dir/sonarqube_data" "$sonarqube_dir/sonarqube_extensions" "$sonarqube_dir/sonarqube_logs" "$sonarqube_dir/sonarqube_temp" "$sonarqube_dir/docker-compose.yml" || display_error "Failed to remove directories and files"

# Ask the user if Docker Compose should be uninstalled
read -p "Do you want to uninstall Docker Compose? (yes/no): " uninstall_docker_compose

if [ "$uninstall_docker_compose" == "yes" ]; then
    # Check if Docker Compose was installed by the setup script and remove it
    if [ -f /usr/local/bin/docker-compose ]; then
        display_notification "Removing Docker Compose..."
        rm /usr/local/bin/docker-compose || display_error "Failed to remove Docker Compose"
        display_success "Docker Compose has been removed."
    else
        display_notification "Docker Compose was not installed by the setup script or is not found in /usr/local/bin."
    fi
else
    display_notification "Docker Compose will not be uninstalled."
fi

# Notify the user
display_success "SonarQube setup has been reverted."
