#!/bin/bash

set -e

# Function to compare versions
version_ge() {
  [ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]
}

# Install Docker if not already installed
if ! [ -x "$(command -v docker)" ]; then
  echo "Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
else
  echo "Docker is already installed"
fi

# Login to Docker Hub using environment variables
echo "Logging in to Docker Hub..."
echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin docker.mnserviceproviders.com

# Pull the Docker image from Docker Hub
echo "Pulling Docker image..."
docker pull docker.mnserviceproviders.com/php_hellow:v1

# Run the Docker container
echo "Running Docker container..."
docker run -d --name php_hellow_container -p 8080:80 docker.mnserviceproviders.com/php_hellow:v1

# Update package list and install necessary dependencies
sudo apt-get update
sudo apt-get install -y libxkbcommon0 xdg-utils fonts-liberation libcairo2 libgbm1 libgtk-3-0 libgtk-4-1 libpango-1.0-0 libu2f-udev libvulkan1 libxdamage1 wget unzip

# Check for the correct version of Java (OpenJDK 11)
if ! java -version 2>&1 | grep -q "openjdk 11"; then
  echo "Installing OpenJDK 11..."
  sudo apt-get install -y openjdk-11-jdk
else
  echo "OpenJDK 11 is already installed"
fi

# Verify Java installation
java -version

# Check for Google Chrome version 126.0.6478.114
if ! google-chrome --version 2>/dev/null | grep -q "Google Chrome 126.0.6478.114"; then
  echo "Installing Google Chrome..."
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i google-chrome-stable_current_amd64.deb || sudo apt-get install -f -y
else
  echo "Google Chrome 126.0.6478.114 is already installed"
fi

# Verify Chrome installation
google-chrome --version

# Check for ChromeDriver version 126.0.6478.63
if ! chromedriver --version 2>/dev/null | grep -q "ChromeDriver 126.0.6478.63"; then
  echo "Installing ChromeDriver..."
  wget https://storage.googleapis.com/chrome-for-testing-public/126.0.6478.63/linux64/chromedriver-linux64.zip
  unzip chromedriver-linux64.zip
  sudo mv chromedriver-linux64/chromedriver /usr/bin/
  sudo mv /usr/bin/local/chromedriver /usr/bin/chromedriver
  sudo chmod +x /usr/bin/chromedriver
else
  echo "ChromeDriver 126.0.6478.63 is already installed"
fi

# Verify ChromeDriver installation
chromedriver --version

# Set the path to the runnable JAR file
JAR_FILE="/home/development/facebook_runnable.jar"

# Check if the JAR file exists and run the Selenium test script
if [ -f "$JAR_FILE" ]; then
  echo "Running Selenium test script..."
  java -jar $JAR_FILE
else
  echo "Error: Unable to access jarfile $JAR_FILE"
  exit 1
fi
