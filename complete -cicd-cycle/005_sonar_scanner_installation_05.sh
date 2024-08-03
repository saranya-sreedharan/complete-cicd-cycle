#!/bin/bash

# sonar scanner is required to scan the project. it will install and setup sonarqube for using.
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

# Function to display warning message
display_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# Notification for downloading SonarScanner CLI
display_warning "Downloading SonarScanner CLI..."
sudo docker exec -u root jenkins wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip || display_error "Failed to download SonarScanner CLI."
display_success "SonarScanner CLI downloaded successfully."

# Notification for unzipping SonarScanner CLI
display_warning "Unzipping SonarScanner CLI..."
sudo docker exec -u root jenkins unzip -o sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt || display_error "Failed to unzip SonarScanner CLI."
display_success "SonarScanner CLI unzipped successfully."

# Notification for adding SonarScanner CLI to PATH
display_warning "Adding SonarScanner CLI to PATH..."
sudo docker exec -u root jenkins bash -c 'echo "export PATH=\$PATH:/opt/sonar-scanner-5.0.1.3006-linux/bin" >> ~/.bashrc' || display_error "Failed to add SonarScanner CLI to PATH."
display_success "SonarScanner CLI added to PATH successfully."

# Notification for setting SONAR_SCANNER_HOME environment variable
display_warning "Setting SONAR_SCANNER_HOME environment variable..."
sudo docker exec -u root jenkins bash -c 'echo "export SONAR_SCANNER_HOME=/opt/sonar-scanner-5.0.1.3006-linux" >> ~/.bashrc' || display_error "Failed to set SONAR_SCANNER_HOME environment variable."
display_success "SONAR_SCANNER_HOME environment variable set successfully."

# Notification for sourcing the updated .bashrc file
display_warning "Sourcing the updated .bashrc file..."
sudo docker exec -u root jenkins bash -c 'source ~/.bashrc' || display_error "Failed to source the updated .bashrc file."
display_success "Updated .bashrc file sourced successfully."
sleep 5
display_warning "restarting jenkins..."
sudo docker restart jenkins