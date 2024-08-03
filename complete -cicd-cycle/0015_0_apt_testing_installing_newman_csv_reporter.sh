#!/bin/bash

# Define colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print messages in color
print_message() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Install Newman CSV reporter
print_message $YELLOW "Installing Newman CSV reporter..."

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    print_message $RED "npm command not found. Please install Node.js and npm first."
    exit 1
fi

# Try to install the Newman CSV reporter
if sudo docker exec -u root jenkins npm install -g newman-reporter-csv; then
    print_message $GREEN "Newman CSV reporter installed successfully."
else
    print_message $RED "Failed to install Newman CSV reporter."
    exit 1
fi

