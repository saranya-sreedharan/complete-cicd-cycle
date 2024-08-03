#!/bin/bash

#This will create sonar token inside jenkins credentails. Required for scanning project in the pieline

# Colors for formatting
RED='\033[0;31m'      # Red colored text
GREEN='\033[0;32m'    # Green colored text
YELLOW='\033[1;33m'   # Yellow colored text
NC='\033[0m'          # Normal text

# Function to display error message and exit
display_error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to display success message
display_success() {
    echo -e "${GREEN}$1${NC}"
}

# Prompt user for SonarQube token
echo -e "${YELLOW}Please enter your SonarQube token:${NC}"
read -sp "SonarQube token: " sonarqube_token
echo ""

# Prompt user for Jenkins credentials
echo -e "${YELLOW}Please enter your Jenkins credentials:${NC}"
read -p "Jenkins username: " jenkins_username
read -sp "Jenkins password: " jenkins_password
echo ""

# Prompt user for Jenkins URL
echo -e "${YELLOW}Please enter your Jenkins URL (e.g., http://192.168.1.100:8080):${NC}"
read -p "Jenkins URL: " jenkins_url

# Define XML for SonarQube token credentials
SONARQUBE_TOKEN_CREDENTIALS_XML=$(cat <<EOF
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>sonar_qube_token</id>
  <description>SonarQube Token</description>
  <secret>$sonarqube_token</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
EOF
)

# Create SonarQube token credentials XML file
echo "$SONARQUBE_TOKEN_CREDENTIALS_XML" > sonarqube-token-credentials.xml

# Retry mechanism
MAX_RETRIES=5
RETRY_DELAY=10

retry_count=0
success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
    echo -e "${YELLOW}Attempt $(($retry_count + 1)) to create SonarQube token credentials...${NC}"
    sudo docker exec -i jenkins sh -c "java -jar jenkins-cli.jar -auth $jenkins_username:$jenkins_password -s $jenkins_url create-credentials-by-xml system::system::jenkins _ < /dev/stdin" < sonarqube-token-credentials.xml

    if [ $? -eq 0 ]; then
        success=true
        break
    else
        echo -e "${RED}Attempt $(($retry_count + 1)) failed. Retrying in $RETRY_DELAY seconds...${NC}"
        sleep $RETRY_DELAY
        retry_count=$(($retry_count + 1))
    fi
done

if [ "$success" = true ]; then
    display_success "SonarQube token credentials created successfully and automation script completed."
else
    display_error "Failed to create SonarQube token credentials after $MAX_RETRIES attempts."
fi

sleep 10

#restart jenkins
echo -e "${YELLOW}restarting jenkins.......${NC}"
sudo docker restart jenkins