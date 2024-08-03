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

# Remove Docker container
echo -e "${YELLOW}Removing Jenkins container...${NC}"
sudo docker stop jenkins || display_error "Failed to stop Jenkins container."
sudo docker rm -f jenkins || display_error "Failed to remove Jenkins container."

# Remove custom Jenkins image
echo -e "${YELLOW}Removing custom Jenkins image...${NC}"
sudo docker rmi my-custom-jenkins || display_error "Failed to remove custom Jenkins image."

# Remove Docker volumes
echo -e "${YELLOW}Removing Docker volumes...${NC}"
sudo docker volume rm jenkins_data || display_error "Failed to remove Docker volume for Jenkins data."

# Remove Jenkins data directory
echo -e "${YELLOW}Removing Jenkins data directory...${NC}"
rm -rf jenkins_data || display_error "Failed to remove Jenkins data directory."

# Remove Dockerfile
echo -e "${YELLOW}Removing Dockerfile...${NC}"
rm -f dockerfile || display_error "Failed to remove Dockerfile."


# Ask user if they want to uninstall Docker
read -p "Do you want to uninstall Docker? (yes/no): " choice
case "$choice" in
  yes|Yes|y|Y )
    echo -e "${YELLOW}Uninstalling Docker...${NC}"
    sudo apt remove --purge docker.io -y || display_error "Failed to uninstall Docker."
    sudo apt autoremove -y || display_error "Failed to autoremove unnecessary packages."
    ;;
  * )
    echo -e "${YELLOW}Skipping Docker uninstallation...${NC}"
    ;;
esac


# Success message
display_success "Reversion completed successfully."
