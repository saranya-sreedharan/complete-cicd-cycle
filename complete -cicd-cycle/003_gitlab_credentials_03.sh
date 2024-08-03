#!/bin/bash

#This script will create gitlab credentials in the jenkins credentials which is used in the pipeline

# Prompt user for GitLab credentials
read -p "Enter your GitLab username: " gitlab_username
read -sp "Enter your GitLab password: " gitlab_password
echo ""

# Prompt user for Jenkins credentials
read -p "Enter your Jenkins username: " jenkins_username
read -sp "Enter your Jenkins password: " jenkins_password
echo ""

# Prompt user for Jenkins URL
read -p "Enter your Jenkins URL (e.g., http://192.168.1.100:8080): " jenkins_url

# Define XML for GitLab credentials
GITLAB_CREDENTIALS_XML=$(cat <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>gitlab-login</id>
  <description>GitLab Login</description>
  <username>$gitlab_username</username>
  <password>$gitlab_password</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
)

# Create GitLab credentials XML file
echo "$GITLAB_CREDENTIALS_XML" > gitlab-credentials.xml

# Retry mechanism
MAX_RETRIES=5
RETRY_DELAY=10

retry_count=0
success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
  echo "Attempt $(($retry_count + 1)) to create GitLab credentials..."
  sudo docker exec -i jenkins sh -c "java -jar jenkins-cli.jar -auth $jenkins_username:$jenkins_password -s $jenkins_url create-credentials-by-xml system::system::jenkins _ < /dev/stdin" < gitlab-credentials.xml

  if [ $? -eq 0 ]; then
    success=true
    break
  else
    echo "Attempt $(($retry_count + 1)) failed. Retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
    retry_count=$(($retry_count + 1))
  fi
done

if [ "$success" = true ]; then
  echo "GitLab credentials created successfully and automation script completed."
else
  echo "Failed to create GitLab credentials after $MAX_RETRIES attempts."
fi