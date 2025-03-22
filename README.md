# Java Gradle Project

This project is a simple Spring Boot web application built using Gradle. It demonstrates how to compile a Java application and publish the generated JAR artifact to a Maven repository (Nexus) using the Maven Publishing plugin.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Build and Run](#build-and-run)
- [Publishing the Artifact](#publishing-the-artifact)
- [Gradle Configuration Details](#gradle-configuration-details)
- [Troubleshooting](#troubleshooting)
- [Docker Integration (Part-2)](#docker-integration-part-2)
- [CI/CD Pipeline (Part-3)](#cicd-pipeline-part-3)
- [Jenkins Shared Library Setup and Basic Usage (Part-4)](#jenkins-shared-library-setup-and-basic-usage-part-4)

## Overview

This Java project leverages Spring Boot to build a web application. In addition to running the application, it includes a custom Gradle configuration for publishing the JAR artifact to a Nexus repository. The project demonstrates:
- Secure publishing configuration via `gradle.properties`
- Allowing an insecure (HTTP) protocol in controlled environments

## Features

- **Maven Publishing:** Publishes snapshots to a Nexus repository.
- **Gradle Build Automation:** Automated build and publish processes.

## Prerequisites

- **Java Development Kit (JDK):** JDK 17 (or higher) must be installed.
- **Gradle Wrapper:** The project includes a Gradle wrapper; no separate installation is required.
- **Nexus Repository:** A Nexus instance (or any Maven repository) running at `http://localhost:8081/repository/maven-snapshots/` (update URL as needed).

## Getting Started

1. **Clone the Repository:**
   ```sh
   git clone <repository-url>
   cd java-gradle-project
   ```
2. **Configure Repository Credentials:**
   Create or update the `gradle.properties` file in the project root with:
   ```properties
   repoUser=your-username
   repoPassword=your-password
   ```

## Build and Run

Build the project using the Gradle wrapper:
```sh
./gradlew build
```
Run the Spring Boot application:
```sh
./gradlew bootRun
```
The compiled JAR file is located in the `build/libs/` directory.

## Publishing the Artifact

1. **Ensure your Nexus repository is running.**
2. **Publish the Artifact:**
   ```sh
   ./gradlew publish
   ```
This command publishes the artifact (`java-gradle-project-1.0-SNAPSHOT.jar`) to the configured Nexus repository.

### Note on Insecure Protocol

Since the Nexus repository URL uses HTTP (`http://localhost:8081`), which is insecure, add the following to your Gradle configuration:
```groovy
allowInsecureProtocol = true
```

## Gradle Configuration Details

- **Plugins Used:**
  - `maven-publish` – Publishes artifacts to a Maven repository.
- **Artifact Configuration:**
  ```groovy
  artifact(file("build/libs/java-gradle-project-${version}.jar")) {
      extension = 'jar'
  }
  ```

## Troubleshooting

- **Error: "No such property: jar for class: java.lang.String"**  
  Verify the string interpolation is correctly formatted:
  ```groovy
  "build/libs/java-gradle-project-${version}.jar"
  ```
- **Insecure Protocol Issues:**  
  Ensure `allowInsecureProtocol = true` is set in the Gradle configuration.

## Proof of Nexus Repository

Below is a screenshot showing the Nexus repository after a successful publish:
![Nexus Repository Screenshot](screenshot/nexus-screenshot.png)

## Docker Integration (Part-2)

This section expands the project by creating a Docker image and pushing it to the Nexus Repository Manager using the previously generated `.jar` file.

1. **Docker Login to Nexus Repository:**
   ```sh
   docker login <nexus-server-ip>:<docker-repository-port>
   ```
   Replace `<nexus-server-ip>` and `<docker-repository-port>` with your Nexus server details. You will be prompted for your Nexus username and password.
2. **Docker Authentication and Config.json:**
   Upon login, Docker stores an authentication token in:
   - **Linux/macOS:** `~/.docker/config.json`
3. **Pushing a Docker Image to Nexus:**
   - **Build a Docker Image:**
     ```sh
     docker build -t <image-name>:<tag> .
     ```
   - **Tag the Image for Nexus Registry:**
     ```sh
     docker tag <local-image-name>:<local-tag> <nexus-registry-endpoint>/<image-name>:<tag>
     ```
   - **Push the Retagged Image:**
     ```sh
     docker push <nexus-registry-endpoint>/<image-name>:<tag>
     ```
4. **Verifying the Pushed Image:**
   Check the image in your Nexus Docker Hosted repository via the Nexus UI.
5. **Retrieving Docker Image Information:**
   ```sh
   curl -u <nexus-username>:<nexus-password> -X GET 'http://<nexus-server-ip>:8081/service/rest/v1/components?repository=<docker-repository-name>'
   ```
   Replace placeholders as needed.
6. **Proof of Nexus Docker Image:**
   ![Docker Image Screenshot](screenshot/docker-screenshot.png)

## CI/CD Pipeline (Part-3)

This section outlines the CI/CD process for the project. The Jenkins pipeline loads an external script (`script.groovy`) which defines methods for:
- **Building the JAR:** Compiles the project and creates the JAR file.
- **Building a Docker Image:** Uses the JAR to build a Docker image.
- **Deploying the Application:** Deploys the application based on the defined strategy.

Additionally, the pipeline automates the upload of the Docker image to a private Docker Hub repository. Below is a screenshot showing proof of the Docker image upload from the CI/CD pipeline:
![Docker Hub Upload Screenshot](screenshot/dockerhub-screenshot.png)

## Jenkins Shared Library Setup and Basic Usage (Part-4)

As part of implementing the Shared Library, the following functions were created in the `vars/` directory to encapsulate build logic:

### `vars/buildImage.groovy`
This function builds and pushes a Docker image to Docker Hub.
```groovy
#!/usr/bin/env groovy

def call(String imageName) {
    echo 'Building the docker image'
    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
        sh "docker build -t ${imageName} ."
        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
        sh "docker push ${imageName}"
    }
}
```
**Explanation:**  
- Accepts an `imageName` parameter to specify the Docker image name and tag.
- Uses `withCredentials` to securely access Docker Hub credentials.
- Executes shell commands to build the Docker image, log in to Docker Hub, and push the image.

### `vars/buildJar.groovy`
This function builds the Java application using Gradle.
```groovy
#!/usr/bin/env groovy

def call() {
    echo "Building the application for branch $BRANCH_NAME"
    sh "./gradlew build"
}
```
**Explanation:**  
- No parameters are needed.
- Prints a message indicating the branch being built.
- Executes the Gradle build command to compile the application and create the JAR file.

### Jenkinsfile Using Shared Library Functions
```groovy
@Library('devops-shared-lib@feature_branch') _
pipeline {
    agent any
    stages {
        stage("build jar") {
            steps {
                script {
                    buildJar() // Build the JAR file using the shared library function.
                }
            }
        }
        stage("build image") {
            steps {
                script {
                    buildImage("kalki2878/java-gradle-app:latest") // Build the Docker image using the shared library function.
                }
            }
        }
    }
}
```
**Explanation:**  
- The `@Library` annotation loads the shared library from the specified branch (`feature_branch`).
- The pipeline includes two stages:
  - **build jar:** Calls `buildJar()` to compile the Java application.
  - **build image:** Calls `buildImage()` with the Docker image name to build and push the Docker image.
- This setup allows centralized management of build logic via the shared library.

Below is the continuation of the README.md file. You can append the following text to your existing README.md file as an additional section documenting the improvements made to the Jenkins deployment pipeline (Parts 5–8).

---

## Jenkins Deployment Pipeline Improvements (Parts 5–8)

This section documents enhancements made to the Jenkins deployment process for my Java Gradle application. The improvements cover:

- **Part 5:** Deploying multiple containers using Docker Compose
- **Part 6:** Dynamically replacing a hard-coded Docker image with a newly built version
- **Part 7:** Extracting deployment commands into a reusable shell script
- **Part 8:** Replacing the Docker image in the Docker Compose file with a dynamically generated version

---

### Part 5: Deploying Multiple Containers with Docker Compose

#### Overview

In this part, I upgraded my deployment from running a single Docker container to managing a multi-container setup via Docker Compose. This is ideal for smaller projects where you need to run both your application and a database (or other services) together.

#### Prerequisites

- **EC2 Instance:** Docker and Docker Compose must be installed.
- **Jenkins:** Configured with the SSH Agent Plugin and appropriate SSH credentials (e.g., `ec2-server-key`).

#### Steps

1. **Install Docker Compose on EC2:**
   ```bash
   sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   docker-compose --version
   ```
2. **Create a `docker-compose.yaml` file:**
   ```yaml
   version: '3.8'
   services:
     java-gradle-app:
       image: kalki2878/java-gradle-app:latest
       ports:
         - "8080:8080"
     postgres:
       image: postgres:13
       ports:
         - "5432:5432"
       environment:
         - POSTGRES_PASSWORD=my-pwd
   ```
3. **Update the Jenkins Pipeline Deploy Stage:**
   ```groovy
   stage("deploy") {
       steps {
           script {
               echo 'Deploying application using Docker Compose...'
               def dockerComposeCmd = "docker-compose -f docker-compose.yaml up --detach"
               sshagent(['ec2-server-key']) {
                   sh "scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@18.184.54.160:/home/ec2-user"
                   sh "ssh -o StrictHostKeyChecking=no ubuntu@18.184.54.160 ${dockerComposeCmd}"
               }
           }
       }
   }
   ```
4. **Verification:**
   - On EC2, run `docker ps` and check `/home/ec2-user/` to confirm files and running containers.

---

### Part 6: Dynamic Image Tagging in Docker Compose

#### Overview

Instead of hard-coding the image name in your Docker Compose file, I made the image tag dynamic. This allows the deployment to automatically use the newly built Docker image from each Jenkins build.

#### Steps

1. **Modify `docker-compose.yaml`:**  
   Replace the hard-coded image name with a variable placeholder:
   ```yaml
   version: '3.8'
   services:
     java-maven-app:
       image: ${IMAGE}
       ports:
         - "8080:8080"
     postgres:
       image: postgres:13
       ports:
         - "5432:5432"
       environment:
         - POSTGRES_PASSWORD=my-pwd
   ```
2. **Update the Shell Script (`server-cmds.sh`):**
   ```bash
   #!/usr/bin/env bash
   # Accept the image name as the first parameter and export it as an environment variable
   export IMAGE=$1
   # Execute Docker Compose using the updated image variable
   docker-compose -f docker-compose.yml up --detach
   echo "Deployment successful!"
   ```
   *Make sure to set the script as executable (`chmod +x server-cmds.sh`).*

3. Update the Jenkinsfile

4. **Verification:**
   - On the EC2 instance, verify that `docker ps` shows the container running the new image tag.

---

### Part 7: Extracting Deployment Commands into a Shell Script

#### Overview

To simplify my Jenkinsfile and make my deployment process more modular, I extracted the remote commands into a standalone shell script. This approach is useful for running multiple commands (e.g., setting variables, copying files, executing Docker Compose) in a single, maintainable script.

#### Steps

1. **Create the Shell Script (`server-cmds.sh`):**
   ```bash
   #!/usr/bin/env bash
   # Accept the image name as the first parameter and set it as an environment variable
   export IMAGE=$1

   # Execute Docker Compose using the docker-compose.yaml file in detached mode
   docker-compose -f docker-compose.yml up --detach

   echo "Deployment successful!"
   ```
   *Ensure this script is executable (`chmod +x server-cmds.sh`).*
2. **Update the Jenkinsfile Deploy Stage:**
   ```groovy
   stage("deploy") {
       steps {
           script {
               echo 'Deploying docker image to EC2 using a shell script...'
               def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
               sshagent(['ec2-server-key']) {
                   sh "scp -o StrictHostKeyChecking=no docker-compose.yml ${EC2_IP}:/home/ubuntu"
                   sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${EC2_IP}:/home/ubuntu"
                   sh "ssh -o StrictHostKeyChecking=no ${EC2_IP} ${shellCmd}"
               }
           }
       }
   }
   ```
3. **Verification:**
   - Confirm file transfer by checking `/home/ubuntu/` on the EC2 instance.
   - Use `docker ps` to verify containers are running.

---

### Part 8: Replacing the Docker Image with a Newly Built Version

#### Overview

In this final improvement, I made the Docker Compose file dynamic so that it always uses the latest built image version. Instead of a hard-coded image name, I used a placeholder that is replaced at deployment time with the newly built image tag.

#### Steps

1. **Modify the Docker Compose File:**
   Change the image field to use a variable placeholder:
   ```yaml
   version: '3.8'
   services:
     java-maven-app:
       image: ${IMAGE}    # Placeholder for the dynamic image name
       ports:
         - "8080:8080"
     postgres:
       image: postgres:13
       ports:
         - "5432:5432"
       environment:
         - POSTGRES_PASSWORD=my-pwd
   ```
2. **Update the Shell Script to Accept a Parameter:**
   The shell script (`server-cmds.sh`) should already be set up to accept the image name:
   ```bash
   #!/usr/bin/env bash
   export IMAGE=$1
   docker-compose -f docker-compose.yaml up --detach
   echo "Deployment successful!"
   ```
3. **Update the Jenkinsfile to Pass the Dynamic Image Name:**
   Ensure the dynamic image name is passed from Jenkins to the shell script:
   ```groovy
   pipeline {
       agent any
       environment {
           // The dynamic image name (e.g., version is updated on each build)
           IMAGE_NAME = "kalki2878/java-gradle-app:2.0"
           EC2_IP = "ec2-user@35.180.251.121"
       }
       stages {
           stage("build jar") {
               steps {
                   script {
                       buildJar()
                   }
               }
           }
           stage("build image") {
               steps {
                   script {
                       buildImage(env.IMAGE_NAME)
                   }
               }
           }
           stage("deploy") {
               steps {
                   script {
                       echo 'Deploying updated Docker image using Docker Compose...'
                       def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                       sshagent(['ec2-server-key']) {
                           sh "scp -o StrictHostKeyChecking=no docker-compose.yml ${EC2_IP}:/home/ubuntu"
                           sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${EC2_IP}:/home/ubuntu"
                           sh "ssh -o StrictHostKeyChecking=no ${EC2_IP} ${shellCmd}"
                       }
                   }
               }
           }
       }
   }
   ```
   *Here, the dynamic image name replaces the hard-coded value in the Docker Compose file at runtime.*
4. **Verification:**
   - On EC2, verify with `docker ps` that containers are running the newly tagged image.


This approach ensures that every new build automatically deploys the latest image version to my EC2 instance without manual intervention.

