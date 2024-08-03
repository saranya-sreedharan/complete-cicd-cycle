#!/bin/bash

# Update and upgrade the system
sudo docker exec -u root jenkins apt-get update -y
sudo docker exec -u root jenkins apt-get upgrade -y

# Download and install JMeter
sudo docker exec -u root jenkins wget https://downloads.apache.org/jmeter/binaries/apache-jmeter-5.6.3.tgz
sudo docker exec -u root jenkins tar -xvzf apache-jmeter-5.6.3.tgz
sudo docker exec -u root jenkins mv apache-jmeter-5.6.3 /opt/apache-jmeter-5.6.3

# Configure environment variables for JMeter
sudo docker exec -u root jenkins bash -c "echo 'export JMETER_HOME=/opt/apache-jmeter-5.6.3' >> ~/.bashrc"
sudo docker exec -u root jenkins bash -c "echo 'export PATH=\$JMETER_HOME/bin:\$PATH' >> ~/.bashrc"
sudo docker exec -u root jenkins bash -c "source ~/.bashrc"

# Verify JMeter installation
sudo docker exec -u root jenkins jmeter -v
