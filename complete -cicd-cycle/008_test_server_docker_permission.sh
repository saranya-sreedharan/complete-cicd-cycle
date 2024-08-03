#!/bin/bash

# if you are a user in the test server and while trying to use manually also "sudo", if asking the password, then set the user like this to run the docker commands 

# Create docker group if it doesn't exist
if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd docker
fi

# Add user to the docker group
sudo usermod -aG docker development

# Apply new group membership in the current session
newgrp docker <<EOF
docker run hello-world
EOF