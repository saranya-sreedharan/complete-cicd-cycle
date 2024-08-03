#!/bin/bash
# This script will revert the changes made by the previous script
# It will uninstall wget, nano, jenkins-cli.jar and the specified plugins from the Jenkins container


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

# Function to uninstall plugins
uninstall_plugin() {
    local plugin=$1
    local message=$2
    echo -e "${BLUE}Uninstalling $plugin plugin...${NC}"
    sudo docker exec -u root jenkins java -jar jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_PASSWORD -s $JENKINS_URL uninstall-plugin $plugin || display_error "$message"
    display_success "$plugin plugin uninstalled successfully."
}

# Prompt the user for Jenkins credentials and URL
read -p "Enter Jenkins username: " JENKINS_USER
read -sp "Enter Jenkins password: " JENKINS_PASSWORD
echo
read -p "Enter Jenkins URL (e.g., http://10.18.22.172:49164): " JENKINS_URL

echo -e "${YELLOW}Removing wget...${NC}"
sudo docker exec -u root jenkins apt-get remove -y wget || display_error "Failed to remove wget."

echo -e "${YELLOW}Removing nano...${NC}"
sudo docker exec -u root jenkins apt-get remove -y nano || display_error "Failed to remove nano."

echo -e "${YELLOW}Deleting Jenkins CLI jar...${NC}"
sudo docker exec -u root jenkins rm -f jenkins-cli.jar || display_error "Failed to delete jenkins-cli.jar."

# Uninstall unnecessary plugins
uninstall_plugin gitlab-plugin "Failed to uninstall GitLab plugin."
uninstall_plugin sonar "Failed to uninstall sonar plugin."
uninstall_plugin testng-plugin "Failed to uninstall testng plugin."
uninstall_plugin behave-testresults-publisher "Failed to uninstall behave-testresults-publisher plugin."
uninstall_plugin Robot "Failed to uninstall Robot plugin."
uninstall_plugin performance "Failed to uninstall performance plugin."
uninstall_plugin xunit "Failed to uninstall xunit plugin."
uninstall_plugin sauce-ondemand "Failed to uninstall sauce-ondemand plugin."
uninstall_plugin Gatling "Failed to uninstall Gatling plugin."
uninstall_plugin ZAP "Failed to uninstall ZAP plugin."

display_success "All changes reverted successfully."

#restart jenkins once the uninstallation is completed.
sudo docker restart jenkins
