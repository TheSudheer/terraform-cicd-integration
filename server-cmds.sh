#!/usr/bin/env bash
# This script runs on the EC2 instance to deploy my Docker Compose setup

# Start Docker Compose in detached mode using the docker-compose.yaml file
docker-compose -f docker-compose.yml up --detach

# Print a success message
echo "Deployment successful!"

