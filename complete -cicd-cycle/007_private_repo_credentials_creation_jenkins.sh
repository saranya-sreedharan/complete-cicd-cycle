#!/bin/bash

#This script will create the docker private credentails in the jenkins to do the push operation

# Colors for formatting
RED='\033[0;31m'      # Red colored text
GREEN='\033[0;32m'    # Green colored text
YELLOW='\033[1;33m'   # Yellow colored text
NC='\033[0m'          # Normal text

# Prompt user for Docker private repo credentials
read -p "Enter your Docker private repo username: " docker_username
read -sp "Enter your Docker private repo password: " docker_password
echo ""

# Prompt user for Jenkins credentials
read -p "Enter your Jenkins username: " jenkins_username
read -sp "Enter your Jenkins password: " jenkins_password
echo ""

# Prompt user for Jenkins URL
read -p "Enter your Jenkins URL (e.g., http://192.168.1.100:8080): " jenkins_url

# Define XML for Docker credentials
DOCKER_CREDENTIALS_XML=$(cat <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>docker-repo-credentials</id>
  <description>Docker Repository Login</description>
  <username>$docker_username</username>
  <password>$docker_password</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
)

# Create Docker credentials XML file
echo "$DOCKER_CREDENTIALS_XML" > docker-credentials.xml

# Retry mechanism
MAX_RETRIES=5
RETRY_DELAY=10

retry_count=1
success=false

while [ $retry_count -le $MAX_RETRIES ]; do
  echo "Attempt $retry_count to create Docker credentials..."
  sudo docker exec -i jenkins sh -c "java -jar jenkins-cli.jar -auth $jenkins_username:$jenkins_password -s $jenkins_url create-credentials-by-xml system::system::jenkins _ < /dev/stdin" < docker-credentials.xml

  if [ $? -eq 0 ]; then
    success=true
    break
  else
    echo "Attempt $retry_count failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
    retry_count=$((retry_count + 1))
  fi
done

if [ "$success" = true ]; then
  echo "Docker credentials created successfully and automation script completed."
else
  echo "Failed to create Docker credentials after $MAX_RETRIES attempts."
fi

