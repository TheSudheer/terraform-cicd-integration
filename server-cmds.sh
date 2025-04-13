#!/usr/bin/env bash
# This script runs on the EC2 instance to deploy my Docker Compose setup

# Accept the image name as the first parameter
export IMAGE=$1
export DOCKER_USER=$2
export DOCKER_PWD=$3

echo $DOCKER_PWD | docker login -u $DOCKER_USER --password-stdin

# Start Docker Compose in detached mode using the docker-compose.yaml file
docker-compose -f docker-compose.yml up --detach

# Print a success message
echo "Deployment successful!"


