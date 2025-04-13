#!/bin/bash
set -e

# Update the system and install Docker
sudo yum -y update && sudo yum -y install docker

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Set permissions on Docker socket
sudo chmod 666 /var/run/docker.sock

# Add the current user (default to ec2-user) to the docker group
sudo usermod -aG docker "${USER:-ec2-user}"

# Wait a few seconds to ensure Docker is fully ready
sleep 5

# Pull and run the NGINX container in detached mode
sudo docker run -d --name nginx-container -p 8080:80 nginx

#Install Docker-compose
curl -SL "https://github.com/docker/compose/releases/download/v2.35.0/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
