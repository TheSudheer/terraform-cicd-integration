# CI/CD Pipeline for Java/Gradle Application Using Jenkins, AWS ECR, and AWS EKS

This repository contains the `Jenkinsfile` and associated configurations for a Continuous Integration and Continuous Deployment (CI/CD) pipeline. The pipeline automates the process of building a Java/Gradle application, generating a JAR file, building a Docker image, pushing it to AWS Elastic Container Registry (ECR), and deploying it to an AWS Elastic Kubernetes Service (EKS) cluster.

**Objective:**  
To demonstrate a functional CI/CD workflow for deploying containerized Java applications to Kubernetes on AWS, leveraging Jenkins Shared Libraries.

---

## Proof of Execution (Screenshots)

### 1. AWS ECR Image Push

*Description:* This screenshot shows the AWS ECR repository (`java-gradle-app`) containing the Docker image pushed by the Jenkins pipeline, tagged as `latest` (or the relevant tag if modified).

![AWS ECR Image Push Success](/screenshot/aws_ecr_screenshot.png)

### 2. AWS EKS Cluster Deployment

*Description:* This screenshot shows the application running successfully on the AWS EKS cluster (`demo-cluster-3`). The view may display running pods (`kubectl get pods`), the service (`kubectl get svc`), or the worker nodes.

![AWS EKS Deployment Success](/screenshot/aws_eks_screenshot.png)
---

## Prerequisites

Before running the pipeline, ensure the following prerequisites are met:

1. **Jenkins Server:**  
   - A running Jenkins instance.

2. **Jenkins Plugins:**
   - Pipeline  
   - Pipeline: Shared Groovy Libraries  
   - Git  
   - Credentials Binding  
   - Docker Pipeline (or Docker plugin)  
   - AWS Steps (or ensure AWS CLI is installed and configured on the agent)  
   - Kubernetes CLI Plugin (or ensure `kubectl` is installed on the agent)  
   - Gradle Plugin

3. **Jenkins Global Tool Configuration:**
   - **Gradle:** A Gradle installation configured with the name `Gradle 7.6.1`.

4. **Jenkins Agent Configuration:**
   - The Jenkins agent (`agent any` implies any available agent) must have Docker, AWS CLI, `kubectl`, and `envsubst` (usually part of the `gettext` package) installed.
   - The agent must have network connectivity to GitHub (for the Shared Library), AWS ECR, and the AWS EKS cluster API endpoint.
   - The user running the Jenkins agent process requires permissions to execute Docker commands.

5. **Source Code Repository:**  
   The repository must include:
   - A `build.gradle` file.
   - A `Dockerfile` in the root directory to build the application image.
   - Kubernetes manifest files (e.g., `kubernetes/deployment.yaml`, `kubernetes/service.yaml`) prepared with placeholders for `envsubst` substitution.

6. **Jenkins Shared Library:**
   - Ensure Jenkins can clone the repository: `https://github.com/TheSudheer/Jenkins-shared-library.git`.

7. **AWS Account & Resources:**
   - An active AWS Account.
   - An **ECR Repository** (e.g., `java-gradle-app` in the `ap-south-1` region).
   - An **EKS Cluster** (e.g., `demo-cluster-3` in the `ap-south-1` region).
   - **IAM Permissions:** AWS credentials must have sufficient permissions for ECR push operations (like `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, etc.) and for EKS interaction (`eks:DescribeCluster` for `update-kubeconfig`). Additionally, `kubectl` commands require appropriate Kubernetes RBAC permissions within the cluster.

8. **Jenkins Credentials:**
   - `GitHub`: Credential (SSH key or username/password/token) for cloning the Shared Library repository.
   - `jenkins_aws_access_key_id`: AWS Access Key ID (as Jenkins Secret Text credential).
   - `jenkins_aws_secret_access_key`: AWS Secret Access Key (as Jenkins Secret Text credential).

---

## Pipeline Overview

The `Jenkinsfile` outlines a declarative pipeline with key components as described below:

1. **Shared Library:**
   - Imports the `devops-shared-lib@master` library using `GitHub` credentials.
   - Uses functions like `buildJar()` and `aws_Ecr()`, which are defined within the shared library.

2. **Agent & Tools:**
   - Configured to run on `agent any`.
   - Uses the Gradle tool defined as `Gradle 7.6.1`.

3. **Options:**
   - Establishes a global pipeline timeout of 10 minutes.

4. **Global Environment Variables:**
   - `AWS_ECR_SERVER`: AWS ECR registry endpoint URL.
   - `AWS_ECR_REPO`: Full URI of the target ECR repository.
   - `imageName`: Defaults to the Docker image tag `latest`.  
     > **Note:** Consider using a dynamic tag (e.g., `${env.BUILD_NUMBER}` or a Git commit hash) for better traceability.

5. **Pipeline Stages:**
   - **`build jar`:**  
     - Invokes `buildJar()` from the shared library to compile the Java code and generate a JAR file.
     - Includes a 3-minute timeout.
   - **`build image`:**  
     - Invokes `aws_Ecr(env.AWS_ECR_REPO, env.imageName)` from the shared library to:
       - Build the Docker image using the local `Dockerfile`.
       - Log in to AWS ECR.
       - Tag and push the image to the ECR repository.
     - Includes a 3-minute timeout.
   - **`Configure Kubeconfig and Test Connectivity`:**  
     - Injects AWS credentials (`jenkins_aws_access_key_id`, `jenkins_aws_secret_access_key`).
     - Runs shell commands to:
       - Verify AWS CLI installation.
       - Set the default AWS region to `ap-south-1`.
       - Update the agent's `kubeconfig` for access to the `demo-cluster-3` EKS cluster.
       - Execute `kubectl get nodes` to verify connectivity.
     - Includes a 3-minute timeout.
   - **`deploy`:**  
     - Re-injects AWS credentials using the `credentials()` helper.
     - Sets `APP_NAME` and `IMAGE_NAME` environment variables.
     - Executes shell commands that:
       - Use `envsubst` to inject environment variables into `kubernetes/deployment.yaml` and `kubernetes/service.yaml`.
       - Deploy the application to the EKS cluster with `kubectl apply -f -`.
     - Includes a 3-minute timeout.

---

## How to Run

1. **Verify Prerequisites:**  
   Confirm all necessary AWS resources, Jenkins configurations, credentials, and source code are in place.

2. **Create a New Pipeline Job in Jenkins:**
   - In the Jenkins UI, create a new Pipeline job.
   - Configure the job to use "Pipeline script from SCM".
   - Set the SCM to Git and provide the repository URL containing your application code.
   - Specify the branch (e.g., `main` or `master`).
   - Select the appropriate `GitHub` credential if accessing a private repository.
   - Ensure the "Script Path" is set to `Jenkinsfile`.

3. **Run the Pipeline:**
   - Save the job configuration.
   - Click "Build Now".
   - Monitor the pipeline execution via the Jenkins UI and check log outputs for each stage (shared library steps, AWS CLI commands, `kubectl` commands, and Docker operations).

---

## Shared Library Usage

This pipeline leverages a Jenkins Shared Library hosted at [TheSudheer/Jenkins-shared-library](https://github.com/TheSudheer/Jenkins-shared-library.git). Key functions include:

- **`buildJar()`:**  
  Responsible for compiling the Java/Gradle project.

- **`aws_Ecr(repo, tag)`:**  
  Handles building the Docker image, tagging it appropriately, logging in to AWS ECR, and pushing the image to the specified repository.

For detailed functionality, refer to the documentation provided with the shared library.

---

## Kubernetes Manifests and `envsubst`

The deployment stage uses `envsubst` to substitute environment variables into Kubernetes manifest files before applying them. Ensure that placeholders in your manifests follow the format `${VAR_NAME}`. For instance:

```yaml
# Example snippet from deployment.yaml
spec:
  template:
    spec:
      containers:
        - name: ${APP_NAME}            # Placeholder for application name
          image: ${AWS_ECR_REPO}:${IMAGE_NAME}   # Placeholders for ECR repository and image tag
```
---
