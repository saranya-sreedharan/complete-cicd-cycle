#!/bin/bash

# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Prompt for Jenkins and other dynamic values
read -p "Enter Jenkins URL (without trailing slash): " JENKINS_URL
read -p "Enter Jenkins Username: " JENKINS_USER
read -sp "Enter Jenkins Password: " JENKINS_PASSWORD
echo
read -p "Enter Job Name: " JOB_NAME

# Define the job configuration XML content with dynamic values
JOB_CONFIG_XML=$(cat <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.42">
  <actions/>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig plugin="pipeline-model-definition@1.10.2">
      <dockerLabel></dockerLabel>
      <registry plugin="docker-commons@1.17"/>
      <registryCredentialId></registryCredentialId>
    </org.jenkinsci.plugins.pipeline.modeldefinition.config.FolderConfig>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.90">
    <script>
pipeline {
  agent any

  stages {
    stage('Checkout') {
      steps {
        script {
          // Checkout the git repository
          git branch: 'main', credentialsId: 'gitlab-login', url: 'https://gitlab.com/practice-group9221502/cicd-project.git'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        // Perform SonarQube analysis
        withCredentials([string(credentialsId: 'sonar_qube_token', variable: 'SONAR_TOKEN')]) {
          sh '''
            /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
            -Dsonar.projectKey=cicd_project \
            -Dsonar.sources=. \
            -Dsonar.host.url=http://54.172.113.45/:9001/ \
            -Dsonar.login=\$SONAR_TOKEN
          '''
        }
      }
    }

    stage('Containerizing PHP Application') {
      steps {
        // Build Docker image for PHP application
        echo 'Building Docker image for PHP application...'
        sh 'sudo docker build -t docker.mnserviceproviders.com/api_testing:v1 .'
      }
    }

    stage('Push Docker Image') {
      steps {
        // Push Docker image to private repository
        echo 'Pushing Docker image to private repository...'
        withCredentials([usernamePassword(credentialsId: 'docker-repo-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
          sh '''
            echo \$DOCKER_PASSWORD | sudo docker login -u \$DOCKER_USERNAME --password-stdin docker.mnserviceproviders.com
            sudo docker push docker.mnserviceproviders.com/api_testing:v1
          '''
        }
      }
    }

    stage('Convert and Transfer Script') {
      steps {
        script {
          // Convert and transfer bash script to target machine
          withCredentials([sshUserPrivateKey(credentialsId: 'ssh-credential-id', keyFileVariable: 'SSH_KEY_FILE')]) {
            def bashScript = '/var/jenkins_home/workspace/\$JOB_NAME/deployment_testserver.sh'

            // Convert line endings to Unix format using dos2unix on Jenkins machine
            sh "dos2unix \$bashScript"

            // Transfer script to target machine
            sh "scp -i \$SSH_KEY_FILE \"\$bashScript\" development@54.172.113.45:/home/ubuntu/"

            // Set executable permissions on the script
            sh "ssh -i \$SSH_KEY_FILE development@54.172.113.45 'chmod +x /home/ubuntu/deployment_testserver.sh'"

            // Execute bash script on target machine
            sh "ssh -i \$SSH_KEY_FILE development@54.172.113.45 'bash /home/ubuntu/deployment_testserver.sh'"
          }
        }
      }
    }
  }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
  <!-- GitLab configuration (Note: Ensure correct credentials are used) -->
  <scm class="hudson.plugins.git.GitSCM" plugin="git@4.12.0">
    <configVersion>2</configVersion>
    <userRemoteConfigs>
      <hudson.plugins.git.UserRemoteConfig>
        <url>https://gitlab.com/practice-group9221502/cicd-project.git</url>
        <credentialsId>gitlab-login</credentialsId>
      </hudson.plugins.git.UserRemoteConfig>
    </userRemoteConfigs>
  </scm>
</flow-definition>
EOF
)

# Create the job configuration XML file
echo -e "${JOB_CONFIG_XML}" | sudo tee job_config.xml > /dev/null

# Get the container ID of Jenkins
CONTAINER_ID=$(sudo docker ps -aqf "name=jenkins")

# Extract the IP address of the container
CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$CONTAINER_ID")

# Copy job_config.xml to Jenkins container
echo -e "${YELLOW}... Copying job_config.xml to Jenkins container....${NC}"
sudo docker cp job_config.xml "$CONTAINER_ID":/var/jenkins_home/ || { echo -e "${RED}Failed to copy job_config.xml to Jenkins container.${NC}"; exit 1; }

# Restart Jenkins container
echo -e "${YELLOW}... Restarting Jenkins container....${NC}"
sudo docker restart "$CONTAINER_ID" || { echo -e "${RED}Failed to restart Jenkins container.${NC}"; exit 1; }

sleep 30

# Retry mechanism for job creation
MAX_RETRIES=5
RETRY_DELAY=10

retry_count=0
success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
  echo "Attempt $(($retry_count + 1)) to create job..."
  # Execute Jenkins CLI command to create the job
  sudo docker exec -i "$CONTAINER_ID" sh -c "java -jar jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_PASSWORD -s http://$CONTAINER_IP:49164/ create-job $JOB_NAME < /var/jenkins_home/job_config.xml"

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
  echo "Job created successfully and automation script completed."
else
  echo "Failed to create job after $MAX_RETRIES attempts."
fi

# Additional commands to list jobs and build the job
sudo docker exec -i "$CONTAINER_ID" sh -c "java -jar jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_PASSWORD -s http://$CONTAINER_IP:49164/ list-jobs" || { echo -e "${RED}Failed to list jobs.${NC}"; exit 1; }
sudo docker exec -i "$CONTAINER_ID" sh -c "java -jar jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_PASSWORD -s http://$CONTAINER_IP:49164/ build $JOB_NAME" || { echo -e "${RED}Failed to build job.${NC}"; exit 1; }
