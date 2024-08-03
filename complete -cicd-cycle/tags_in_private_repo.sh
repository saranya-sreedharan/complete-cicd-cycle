#!/bin/bash

# Set your credentials and registry URL
USERNAME="admin"
PASSWORD="password"
REGISTRY_URL="https://saranyadocker.mnserviceproviders.com"

# Fetch the list of repositories
REPOS=$(curl -s -u $USERNAME:$PASSWORD $REGISTRY_URL/v2/_catalog | jq -r '.repositories[]')

# Iterate through each repository and fetch its tags
for REPO in $REPOS; do
    echo "Repository: $REPO"
    TAGS=$(curl -s -u $USERNAME:$PASSWORD $REGISTRY_URL/v2/$REPO/tags/list | jq -r '.tags[]')
    for TAG in $TAGS; do
        echo "  Tag: $TAG"
    done
done