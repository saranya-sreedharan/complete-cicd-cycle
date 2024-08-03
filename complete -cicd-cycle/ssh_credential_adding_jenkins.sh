#!/bin/bash
#make sure run as a root user

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

# Prompt for Jenkins details
read -p "Enter Jenkins URL (e.g., http://192.168.1.100:8080): " JENKINS_URL
read -p "Enter Jenkins Username: " JENKINS_USER
read -p "Enter Jenkins API Token: " JENKINS_API_TOKEN
read -p "Enter a unique ID for the credentials: " CREDENTIALS_ID
read -p "Enter a description for the credentials: " DESCRIPTION
read -p "Enter the SSH username: " SSH_USERNAME

# Prompt for SSH key input and store in a variable
echo -e "${YELLOW}Enter the SSH Private Key below (Ctrl+D to finish):${NC}"
SSH_KEY=$(cat)

# Verify SSH key content is not empty
if [ -z "$SSH_KEY" ]; then
    error_exit "SSH key content cannot be empty."
fi

# Create XML configuration for Jenkins credentials
cat > ssh-credentials.xml <<EOF
<com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey plugin="ssh-credentials@1.18">
    <scope>GLOBAL</scope>
    <id>${CREDENTIALS_ID}</id>
    <description>${DESCRIPTION}</description>
    <username>${SSH_USERNAME}</username>
    <privateKeySource class="com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey\$DirectEntryPrivateKeySource">
        <privateKey>${SSH_KEY}</privateKey>
    </privateKeySource>
    <passphrase></passphrase>
</com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey>
EOF

# Verify if XML file was created
if [ ! -f ssh-credentials.xml ]; then
    error_exit "Failed to create XML configuration file."
fi

# Add credentials to Jenkins using Jenkins CLI
docker exec -i jenkins sh -c "cat > /tmp/ssh-credentials.xml" < ssh-credentials.xml
docker exec -i jenkins sh -c "java -jar jenkins-cli.jar -s ${JENKINS_URL} -auth ${JENKINS_USER}:${JENKINS_API_TOKEN} create-credentials-by-xml system::system::jenkins _ < /tmp/ssh-credentials.xml" || error_exit "Failed to add credentials to Jenkins."

# Clean up the XML file
rm -f ssh-credentials.xml

# Success message
success_msg "SSH key credentials added successfully to Jenkins."

# End of script
