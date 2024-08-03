#!/bin/bash

# This script will set up Jenkins with volume using Docker

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

# Update package repositories
echo -e "${YELLOW}Updating package repositories...${NC}"
sudo apt update || display_error "Failed to update package repositories."

# Check if Docker is installed, if not install it
if ! command -v docker &> /dev/null; then
    display_success "Installing Docker..."
    sudo apt install docker.io -y || display_error "Failed to install Docker"
else
    display_success "Docker is already installed"
fi

# Create Jenkins data directory
echo -e "${YELLOW}Creating Jenkins data directory...${NC}"
mkdir jenkins_data || display_error "Failed to create Jenkins data directory."

# Set permissions for Jenkins data directory
echo -e "${YELLOW}Setting permissions for Jenkins data directory...${NC}"
sudo chown -R 1000:1000 jenkins_data && sudo chmod -R 777 jenkins_data || display_error "Failed to set permissions for Jenkins data directory."

# Create Dockerfile
echo -e "${YELLOW}Creating Dockerfile...${NC}"
cat << EOF | sudo tee Dockerfile > /dev/null
FROM jenkins/jenkins:lts

# Install Docker CLI
USER root
RUN apt-get update && apt-get install -y docker.io

# Add Jenkins user to the Docker group
RUN usermod -aG docker jenkins

# Expose ports for Jenkins web UI and agent communication
EXPOSE 8080 50000

# Set up a volume to persist Jenkins data
VOLUME /var/jenkins_home

# Set up the default command to run Jenkins
CMD ["java", "-jar", "/usr/share/jenkins/jenkins.war"]
EOF
if [ $? -ne 0 ]; then
    display_error "Failed to create Dockerfile."
fi

# Set permissions for Dockerfile
echo -e "${YELLOW}Setting permissions for Dockerfile...${NC}"
sudo chown root:root Dockerfile || display_error "Failed to set permissions for Dockerfile."

# Build custom Jenkins image
echo -e "${YELLOW}Building custom Jenkins image...${NC}"
sudo docker build -t my-custom-jenkins . || display_error "Failed to build custom Jenkins image."

# Run Jenkins container
echo -e "${YELLOW}Running Jenkins container...${NC}"
sudo docker run --name jenkins -d -p 49164:8080 -p 50000:50000 \
    --group-add $(stat -c %g /var/run/docker.sock) \
    -v "$(pwd)/jenkins_data:/var/jenkins_home" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --restart always \
    my-custom-jenkins || display_error "Failed to run Jenkins container."

# Wait for Jenkins to be up and running
sleep 30

# Additional setup inside the Jenkins container
sudo docker exec -u root jenkins apt-get update
sudo docker exec -u root jenkins apt-get install -y wget
sudo docker exec -u root jenkins apt-get install -y sudo
sudo docker exec -u root jenkins apt-get install -y nano
sudo docker exec -u root jenkins apt-get install dos2unix

# Retrieve the initial admin password
echo -e "${YELLOW}Retrieving the initial admin password...${NC}"
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword || display_error "Failed to retrieve the initial admin password."

# Success message
display_success "Jenkins setup completed successfully. You can access Jenkins at http://ip_address:49164"


#login with initial password and create a user with username and password (eg : admin,admin) for the feature operations in jenkins. 