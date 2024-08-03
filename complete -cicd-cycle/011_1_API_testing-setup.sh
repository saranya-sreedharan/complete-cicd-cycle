#!/bin/bash

# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration variables
username="admin"
password="admin"
jenkins_container_name="jenkins"
jenkins_url="http://10.18.21.240:49164"
sonar_db_container_id="f69de104b906"
db_password="sonar"
sonar_db_name="api-test-sonar_db-1"

# Install Jenkins plugins
echo "Installing Jenkins plugins..."
sudo docker exec -u root "$jenkins_container_name" java -jar jenkins-cli.jar -auth "$username:$password" -s "$jenkins_url" install-plugin htmlpublisher || { echo "Failed to install HTML publisher."; exit 1; }
sudo docker exec -u root "$jenkins_container_name" java -jar jenkins-cli.jar -auth "$username:$password" -s "$jenkins_url" install-plugin database-postgresql || { echo "Failed to install PostgreSQL JDBC driver plugin."; exit 1; }

# Install NVM, Node.js, npm, and PostgreSQL JDBC driver
echo "Installing NVM, Node.js, npm, and PostgreSQL JDBC driver..."
sudo docker exec -u root "$jenkins_container_name" curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
sudo docker exec -u root "$jenkins_container_name" apt-get install -y nodejs npm libpostgresql-jdbc-java
sudo docker exec -u root "$jenkins_container_name" cp /usr/share/java/postgresql-42.5.4.jar /var/jenkins_home/war/WEB-INF/lib
sudo docker exec -u root "$jenkins_container_name" chmod 755 /var/jenkins_home/war/WEB-INF/lib

# Verify Node.js and npm installation
echo "Verifying Node.js and npm installation..."
sudo docker exec -u root "$jenkins_container_name" npm -v
sudo docker exec -u root "$jenkins_container_name" node -v
sudo docker exec -u root jenkins apt-get install -y rsync

# Install Newman and HTML reporters
echo "Installing Newman and HTML reporters..."
sudo docker exec -u root "$jenkins_container_name" npm install -g newman newman-reporter-html newman-reporter-htmlextra

# Restart Jenkins container
echo "Restarting Jenkins container..."
sudo docker restart "$jenkins_container_name" || { echo "Failed to restart Jenkins container."; exit 1; }

# Setup PostgreSQL database for HTML reports
echo "Setting up PostgreSQL database for HTML reports..."
sudo docker exec -it "$sonar_db_container_id" psql -U sonar -c "CREATE DATABASE api_test_reports;"
sudo docker exec -it "$sonar_db_container_id" psql -U sonar -d api_test_reports -c "CREATE TABLE reports (name VARCHAR(255), content TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"

# Set up PostgreSQL exporter
echo "Setting up PostgreSQL exporter..."
exporter_dir="/opt/postgres_exporter"
sudo mkdir -p "$exporter_dir"
echo "DATA_SOURCE_NAME=\"postgresql://postgres:$db_password@localhost:5432/postgres?sslmode=disable\"" | sudo tee "$exporter_dir/postgres_exporter.env" > /dev/null

# Create docker-compose file for PostgreSQL exporter
sudo tee "$exporter_dir/docker-compose.yml" > /dev/null <<EOF
version: '3.7'

services:
  postgres_exporter:
    image: wrouesnel/postgres_exporter
    env_file:
      - ./postgres_exporter.env
    network_mode: host
    ports:
      - "9187:9187"
    restart: always
EOF

# Start PostgreSQL exporter
echo "Starting PostgreSQL exporter..."
sudo docker-compose -f "$exporter_dir/docker-compose.yml" up -d || { echo "Failed to start PostgreSQL exporter."; exit 1; }

# Configure PostgreSQL for SonarQube
echo "Configuring PostgreSQL for SonarQube..."
config_file=$(sudo docker exec "$sonar_db_container_id" psql -U sonar -c "SHOW config_file;" | grep -oE "/.*/postgresql.conf")
sudo docker exec "$sonar_db_container_id" sed -i '/^#?port/s/^#//g' "$config_file"
sudo docker exec "$sonar_db_container_id" sed -i '/^#?port/s/5433/5432/g' "$config_file"
pg_hba_conf=$(sudo docker exec "$sonar_db_container_id" psql -U sonar -c "SHOW hba_file;" | grep -oE "/.*/pg_hba.conf")
sudo docker exec "$sonar_db_container_id" sed -i 's/^host.*127.0.0.1\/32.*trust/host all all 0.0.0.0\/0 trust/g' "$pg_hba_conf"

# Create Docker network and connect containers
echo "Creating Docker network and connecting containers..."
sudo docker network create constant_network
sudo docker network connect constant_network "$jenkins_container_name"
sudo docker network connect constant_network "$sonar_db_name"

# Configure Jenkins for script approval and restart
echo "Configuring Jenkins for script approval..."
SCRIPT_PATH="/usr/share/jenkins/ref/init.groovy.d"
SCRIPT_NAME="custom-csp.groovy"
SCRIPT_CONTENT="System.setProperty('hudson.model.DirectoryBrowserSupport.CSP', \"\")"

# Create the script content
echo "$SCRIPT_CONTENT" | sudo tee "$SCRIPT_NAME" > /dev/null
sudo docker cp "$SCRIPT_NAME" "$jenkins_container_name":"$SCRIPT_PATH"/"$SCRIPT_NAME"
rm "$SCRIPT_NAME"
sudo docker restart "$jenkins_container_name"

jenkins_container_name="jenkins"
JENKINS_HOME="/var/jenkins_home"
INIT_GROOVY_D="$JENKINS_HOME/init.groovy.d"
SCRIPT_NAME="approveSignatures.groovy"
SCRIPT_PATH="$INIT_GROOVY_D/$SCRIPT_NAME"

# Create the init.groovy.d directory if it doesn't exist
echo "Creating $INIT_GROOVY_D directory..."
sudo docker exec -u root $jenkins_container_name mkdir -p "$INIT_GROOVY_D"

# Create the Groovy script for approving signatures
echo "Creating the Groovy script for approving signatures..."
sudo docker exec -u root $jenkins_container_name bash -c "cat <<EOF > $SCRIPT_PATH
import jenkins.model.*
import org.jenkinsci.plugins.scriptsecurity.scripts.ScriptApproval

def approvals = [
    'staticMethod groovy.sql.Sql newInstance java.lang.String java.lang.String java.lang.String java.lang.String',
    'method groovy.sql.Sql execute java.lang.String java.util.List',
    'staticMethod java.lang.Class forName java.lang.String'
]

def scriptApproval = ScriptApproval.get()
approvals.each { approval ->
    scriptApproval.approveSignature(approval)
}
EOF"

# Set permissions for the script
echo "Setting permissions for the script..."
sudo docker exec -u root $jenkins_container_name chown -R jenkins:jenkins "$INIT_GROOVY_D"
sudo docker exec -u root $jenkins_container_name chmod +x "$SCRIPT_PATH"

# Restart Jenkins to apply the changes
echo "Restarting Jenkins..."
sudo docker restart $jenkins_container_name

# Confirmation message
echo "Groovy script for script approval has been set up and Jenkins is restarting."

# Confirmation messages
echo "Setup completed successfully."
