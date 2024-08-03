#!/bin/bash

# It will take the key from user and stored in the jenkins container for connection to target machine
# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display error message and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display success message
success_msg() {
    echo -e "${GREEN}$1${NC}"
}

# Main script starts here

# Prompt for SSH key input and store in a file
echo -e "${YELLOW}Enter the SSH Private Key below (Ctrl+D to finish):${NC}"
cat > ec2_pemkey.pem || error_exit "Failed to store SSH key in ec2_pemkey.pem file."
success_msg "SSH key stored successfully in ec2_pemkey.pem file."

# Change permissions of the SSH key file
sudo chmod 600 ec2_pemkey.pem || error_exit "Failed to change permissions of ec2_pemkey.pem file."
success_msg "Permissions changed successfully for ec2_pemkey.pem file."

# Write the SSH key directly to the Jenkins Docker volume
echo -e "${YELLOW}Writing SSH key to Jenkins Docker volume...${NC}"
sudo docker cp ec2_pemkey.pem jenkins:/var/jenkins_home/ || error_exit "Failed to write SSH key to Jenkins Docker volume"
success_msg "SSH key written successfully to /var/jenkins_home/ec2_pemkey.pem inside the Jenkins container."

# Optional: Sleep for some time for user to read messages
sleep 10

# End of script
