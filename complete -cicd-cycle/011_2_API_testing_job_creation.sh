#!/bin/bash

# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

set -e  # Exit immediately if a command exits with a non-zero status.

username="admin"
password="admin"
jenkins_container_name="jenkins"
jenkins_url="http://10.18.21.240:49164"
sonar_db_container_id="f69de104b906"
db_password="sonar"
sonar_db_name="api-test-sonar_db-1"
gitlab_url="https://gitlab.com"
JOB_NAME="cicd-project"
directory_url="https://gitlab.com/practice-group9221502/cicd-project.git"
database_name="api_test_reports"
sonardb_username="sonar"
sonardb_password="sonar"

# Define the job configuration XML content with dynamic values
cat <<EOF > job_definition.xml
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
                      git branch: 'main', credentialsId: 'gitlab-login', url: '${directory_url}'
                  }
              }
          }

          stage('SonarQube Analysis') {
              steps {
                  script {
                      // Perform SonarQube analysis
                      withCredentials([string(credentialsId: 'sonar_qube_token', variable: 'SONAR_TOKEN')]) {
                          sh '''
                              /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                              -Dsonar.projectKey=cicd-project \
                              -Dsonar.sources=. \
                              -Dsonar.host.url=http://10.18.21.240:9001/ \
                              -Dsonar.login=\$SONAR_TOKEN
                          '''
                      }
                  }
              }
          }

          stage('Containerizing PHP Application') {
              steps {
                  script {
                      // Build Docker image for PHP application
                      echo 'Building Docker image for PHP application...'
                      sh 'sudo docker build -t docker.mnserviceproviders.com/php_hellow:v1 .'
                  }
              }
          }

          stage('Push Docker Image') {
              steps {
                  script {
                      // Push Docker image to private repository
                      echo 'Pushing Docker image to private repository...'
                      withCredentials([usernamePassword(credentialsId: 'docker-repo-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                          sh '''
                              echo \$DOCKER_PASSWORD | sudo docker login -u \$DOCKER_USERNAME --password-stdin docker.mnserviceproviders.com
                              sudo docker push docker.mnserviceproviders.com/php_hellow:v1
                          '''
                      }
                  }
              }
          }

          stage('Run API Tests') {
              steps {
                  script {
                      // Run Newman command and generate the report
                      catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                          sh 'newman run /var/jenkins_home/workspace/\$JOB_NAME/mmdev2api.postman_collection__1_.json -r htmlextra'
                      }
                  }
              }
              post {
                  always {
                      script {
                          // Move HTML report to a temporary location
                          sh 'mv /var/jenkins_home/workspace/\$JOB_NAME/newman/*.html /tmp/'

                          // Store HTML reports into PostgreSQL database
                          def htmlReportsDir = "/tmp/"
                          def htmlReports = sh(script: 'ls /tmp/*.html', returnStdout: true).trim().split('\n')

                          htmlReports.each { reportFile ->
                              // Extract report name from file path
                              def reportName = reportFile.tokenize('/').last()

                              // Read HTML report content
                              def reportContent = readFile(file: reportFile).trim()

                              // Store report content into PostgreSQL database
                              storeReportInDatabase(reportName, reportContent)
                          }
                      }
                  }
              }
          }

          stage('Convert and Transfer Script') {
              steps {
                  script {
                      try {
                          // Convert and transfer bash script to target machine
                          withCredentials([sshUserPrivateKey(credentialsId: 'ssh-credential-id', keyFileVariable: 'SSH_KEY_FILE'),
                                           usernamePassword(credentialsId: 'docker-repo-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                              def bashScript = "/var/jenkins_home/workspace/\${env.JOB_NAME}/deployment_testserver.sh"
                              def apiFolder = "/var/jenkins_home/workspace/\${env.JOB_NAME}/newman"

                              // Convert line endings to Unix format using dos2unix on Jenkins machine
                              sh "dos2unix \${bashScript}"

                              // Transfer script and folder to target machine
                              sh """
                                  scp -i \${SSH_KEY_FILE} -o StrictHostKeyChecking=no \${bashScript} development@10.18.21.240:/home/development/
                                  rsync -avz -e "ssh -i \${SSH_KEY_FILE} -o StrictHostKeyChecking=no" \${apiFolder} development@10.18.21.240:/home/development/
                              """

                              // Set executable permissions on the script
                              sh "ssh -i \${SSH_KEY_FILE} development@10.18.21.240 'chmod +x /home/development/deployment_testserver.sh'"

                              // Execute bash script on target machine with environment variables
                              sh "ssh -i \${SSH_KEY_FILE} development@10.18.21.240 'DOCKER_USER=\${DOCKER_USER} DOCKER_PASS=\${DOCKER_PASS} bash /home/development/deployment_testserver.sh'"
                          }
                      } catch (Exception e) {
                          echo "Error during script transfer or execution: \${e.message}"
                          currentBuild.result = 'FAILURE'
                          error("Stopping pipeline due to failure in script transfer or execution.")
                      }
                  }
              }
          }
      }
  }

  def storeReportInDatabase(reportName, reportContent) {
      def dbUrl = "jdbc:postgresql://\$sonar_db_name:5432/\$database_name"
      def dbUser = "\$sonardb_username"
      def dbPassword = "\$sonardb_password"
      def driver = 'org.postgresql.Driver'

      Class.forName(driver)

      // Establish database connection
      def sql = groovy.sql.Sql.newInstance(dbUrl, dbUser, dbPassword, driver)

      // Insert report into database
      sql.execute("INSERT INTO reports (name, content) VALUES (?, ?)", [reportName, reportContent])
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

# Create the job configuration XML file
echo -e "${JOB_CONFIG_XML}" | sudo tee job_config.xml > /dev/null

# Get the container ID of Jenkins
CONTAINER_ID=$(sudo docker ps -aqf "name=$jenkins_container_name")

# Copy job_definition.xml to Jenkins container
sudo docker cp job_definition.xml "$CONTAINER_ID":/var/jenkins_home/ || { echo "Failed to copy job_definition.xml to Jenkins container."; exit 1; }

# Restart Jenkins container
sudo docker restart "$CONTAINER_ID" || { echo "Failed to restart Jenkins container."; exit 1; }

sleep 30

# Retry mechanism for job creation
MAX_RETRIES=5
RETRY_DELAY=10

retry_count=0
success=false

while [ $retry_count -lt $MAX_RETRIES ]; do
  # Execute Jenkins CLI command to create the job
  sudo docker exec -i "$CONTAINER_ID" sh -c "java -jar jenkins-cli.jar -auth $username:$password -s $jenkins_url create-job $JOB_NAME < /var/jenkins_home/job_definition.xml"

  if [ $? -eq 0 ]; then
    success=true
    break
  else
    sleep $RETRY_DELAY
    retry_count=$((retry_count + 1))
  fi
done

if [ "$success" = true ]; then
  echo "Jenkins job '$JOB_NAME' created successfully."
else
  echo "Failed to create Jenkins job '$JOB_NAME' after $MAX_RETRIES attempts."
  exit 1
fi

# List jobs
echo -e "${YELLOW}... Listing jobs....${NC}"
sudo docker exec -i "$jenkins_container_name" sh -c "java -jar jenkins-cli.jar -auth $username:$password -s jenkins_url list-jobs"

# Build the job
echo -e "${YELLOW}... Building the job....${NC}"
sudo docker exec -i "$jenkins_container_name" sh -c "java -jar jenkins-cli.jar -auth $username:$password -s jenkins_url build $job_name"
