#!/bin/bash
# This script will install wget,nano and some testing plugins inside the jnekins container. So Once you done the jenkins_setup, you can run this script
#testing plugins - gitlab-plugin, sonar, testng-plugin, behave-testresults-publisher, Robot, performance, xunit, sauce-ondemand, Gatling, ZAP will be installed

# Colors for text formatting
RED='\033[0;31m'   # Red colored text
NC='\033[0m'       # Normal text
YELLOW='\033[33m'  # Yellow colored text
GREEN='\033[32m'   # Green colored text
BLUE='\033[34m'    # Blue colored text

# Function to display error messages
display_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Function to display success messages
display_success() {
    echo -e "${GREEN}$1${NC}"
}

# Function to install plugins
install_plugin() {
    local plugin=$1
    local message=$2
    echo -e "${BLUE}Installing $plugin plugin...${NC}"
    sudo docker exec -u root jenkins java -jar jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_PASSWORD -s $JENKINS_URL install-plugin $plugin || display_error "$message"
    display_success "$plugin plugin installed successfully."
}

# Prompt the user for Jenkins credentials and URL
read -p "Enter Jenkins username: " JENKINS_USER
read -sp "Enter Jenkins password: " JENKINS_PASSWORD
echo
read -p "Enter Jenkins URL (e.g., http://10.18.22.172:49164): " JENKINS_URL

echo -e "${YELLOW}Updating apt-get...${NC}"
sudo docker exec -u root jenkins apt-get update || display_error "Failed to update apt-get."

echo -e "${YELLOW}Installing wget...${NC}"
sudo docker exec -u root jenkins apt-get install -y wget || display_error "Failed to install wget."

echo -e "${YELLOW}Installing nano...${NC}"
sudo docker exec -u root jenkins apt-get install -y nano || display_error "Failed to install nano."

echo -e "${YELLOW}Downloading Jenkins CLI jar...${NC}"
sudo docker exec -u root jenkins wget "$JENKINS_URL/jnlpJars/jenkins-cli.jar" || display_error "Failed to download jenkins-cli.jar."

# Install necessary plugins
install_plugin gitlab-plugin "Failed to install GitLab plugin."
install_plugin sonar "Failed to install sonar plugin."
install_plugin testng-plugin "Failed to install testng plugin."
install_plugin behave-testresults-publisher "Failed to install behave-testresults-publisher plugin."
install_plugin Robot "Failed to install Robot plugin."
install_plugin performance "Failed to install performance plugin."
install_plugin xunit "Failed to install xunit plugin."
install_plugin sauce-ondemand "Failed to install sauce-ondemand plugin."
install_plugin Gatling "Failed to install Gatling plugin."
install_plugin ZAP "Failed to install ZAP plugin."


display_success "All plugins installed successfully."

#restart jenkins once the installation is completed.
sudo docker restart jenkins
