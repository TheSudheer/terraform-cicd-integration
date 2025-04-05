Okay, here is a detailed README.md file for the provided Jenkinsfile-Shared-Library.

# Jenkins CI/CD Pipeline for Java Gradle Application Deployment to AWS EKS

This repository contains a Jenkinsfile (`Jenkinsfile-Shared-Library`) that defines a CI/CD pipeline for building a Java application using Gradle, containerizing it with Docker, pushing the image to AWS Elastic Container Registry (ECR), and deploying it to an AWS Elastic Kubernetes Service (EKS) cluster.

The pipeline leverages a Jenkins Shared Library for reusable code components.

## Overview

The pipeline automates the following processes:

1.  **Build:** Compiles the Java application and packages it into a JAR file using Gradle.
2.  **Containerize:** Builds a Docker image of the application.
3.  **Push:** Pushes the built Docker image to a specified AWS ECR repository.
4.  **Configure:** Configures `kubectl` to connect to the target AWS EKS cluster.
5.  **Deploy:** Deploys the application to the EKS cluster using Kubernetes manifest files (`deployment.yaml` and `service.yaml`), substituting necessary environment variables.

## Features

*   **Declarative Pipeline:** Uses Jenkins' declarative pipeline syntax for clarity and structure.
*   **Shared Library Integration:** Utilizes a Jenkins Shared Library (`devops-shared-lib`) hosted on GitHub for common tasks (`buildJar`, `aws_Ecr`).
*   **Gradle Build:** Supports building Java applications managed with Gradle.
*   **Docker Integration:** Builds Docker images and pushes them to AWS ECR.
*   **AWS EKS Deployment:** Configures Kubernetes context and deploys application manifests to an EKS cluster.
*   **Credential Management:** Securely handles AWS credentials using the Jenkins Credentials Binding plugin.
*   **Environment Variable Substitution:** Uses `envsubst` to dynamically inject configuration into Kubernetes manifests.
*   **Timeouts:** Implements stage-level and global timeouts for resilience.

## Prerequisites

Before running this pipeline, ensure the following are set up:

1.  **Jenkins Instance:** A running Jenkins controller.
2.  **Jenkins Plugins:**
    *   Pipeline (installed by default)
    *   Git (installed by default)
    *   Pipeline: Groovy Libraries (for Shared Libraries)
    *   Credentials Binding
    *   Workspace Cleanup (Recommended)
    *   Docker Pipeline (Potentially required by the `aws_Ecr` function in the shared library)
    *   Any other plugins required by the `devops-shared-lib`.
3.  **Jenkins Tools:**
    *   **Gradle:** A Gradle installation configured in Jenkins under `Manage Jenkins` -> `Tools`. The pipeline specifically requires a tool named `Gradle 7.6.1`.
4.  **Jenkins Credentials:**
    *   `GitHub`: A credential (e.g., Personal Access Token, SSH Key) with read access to the Shared Library repository (`https://github.com/TheSudheer/Jenkins-shared-library.git`). Used for retrieving the shared library.
    *   `jenkins_aws_access_key_id`: Jenkins String Credential storing the AWS Access Key ID.
    *   `jenkins_aws_secret_access_key`: Jenkins Secret Text Credential storing the AWS Secret Access Key.
    *   *Note:* The AWS credentials need sufficient IAM permissions to:
        *   Authenticate with ECR (`ecr:GetAuthorizationToken`).
        *   Push images to the specified ECR repository (`ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload`, `ecr:PutImage`, etc.).
        *   Describe the EKS cluster (`eks:DescribeCluster`) for `aws eks update-kubeconfig`.
        *   Interact with the EKS cluster via `kubectl` (permissions depend on Kubernetes RBAC configuration, but typically include rights to manage Deployments and Services).
5.  **Shared Library Access:** Jenkins needs network connectivity to `github.com` to fetch the shared library.
6.  **AWS Resources:**
    *   **ECR Repository:** An ECR repository at `710271936636.dkr.ecr.ap-south-1.amazonaws.com/java-gradle-app`.
    *   **EKS Cluster:** An EKS cluster named `demo-cluster-3` in the `ap-south-1` region.
7.  **Agent Environment:** The Jenkins agent(s) where the pipeline runs must have:
    *   `aws cli` installed and configured (or available in the path).
    *   `kubectl` installed and configured (or available in the path).
    *   `envsubst` command available (usually part of `gettext` package).
    *   Docker client installed and configured (likely needed for the `aws_Ecr` shared library function).
    *   Access to the internet (for downloading Gradle dependencies, pulling base Docker images, accessing AWS APIs).
8.  **Project Structure:** The Git repository containing this `Jenkinsfile-Shared-Library` should also contain:
    *   The Java Gradle application source code.
    *   A `Dockerfile` (implicitly used by the `aws_Ecr` shared library function).
    *   A `kubernetes/` directory containing:
        *   `deployment.yaml`: Kubernetes Deployment manifest.
        *   `service.yaml`: Kubernetes Service manifest.
        *   These manifests should use environment variables like `$APP_NAME` and `$IMAGE_NAME` (and potentially `$AWS_ECR_REPO`) where substitutions are needed via `envsubst`.

## Configuration

### Jenkinsfile Variables

The following environment variables are defined within the `Jenkinsfile`:

*   `AWS_ECR_SERVER`: `710271936636.dkr.ecr.ap-south-1.amazonaws.com` - The ECR registry server address.
*   `AWS_ECR_REPO`: `710271936636.dkr.ecr.ap-south-1.amazonaws.com/java-gradle-app` - The full ECR repository path.
*   `imageName`: `latest` - The tag used for the Docker image.

### Shared Library

This pipeline relies heavily on the `devops-shared-lib` shared library from `https://github.com/TheSudheer/Jenkins-shared-library.git`.

```groovy
library identifier: 'devops-shared-lib@master', retriever: modernSCM(
    [
        $class: 'GitSCMSource',
        remote: 'https://github.com/TheSudheer/Jenkins-shared-library.git',
        credentialsId: 'GitHub' // Credential ID configured in Jenkins
    ]
)


The pipeline specifically calls the following functions from the library:

buildJar(): Assumed to execute the Gradle build process (e.g., gradle clean build).

aws_Ecr(env.AWS_ECR_REPO, env.imageName): Assumed to handle Docker image building and pushing to the specified AWS ECR repository and tag.

Pipeline Breakdown

The pipeline consists of the following stages:

build jar:

Prints start and end messages.

Calls the buildJar() function from the shared library.

Likely uses the configured 'Gradle 7.6.1' tool.

Has a 3-minute timeout.

build image:

Prints start and end messages.

Calls the aws_Ecr() function from the shared library, passing the ECR repository path and image tag.

This stage likely performs docker build and docker push operations, potentially including ECR authentication.

Has a 3-minute timeout.

Configure Kubeconfig and Test Connectivity:

Prints start and end messages.

Uses withCredentials to securely inject AWS access key ID and secret key into the environment.

Executes shell commands (sh step):

Verifies the aws cli version.

Sets the AWS_DEFAULT_REGION to ap-south-1.

Updates the local kubeconfig file to grant access to the demo-cluster-3 EKS cluster using the provided AWS credentials.

Tests connectivity by listing Kubernetes nodes (kubectl get nodes).

Has a 3-minute timeout.

deploy:

Prints start and end messages.

Sets stage-specific environment variables:

AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY: Retrieves credentials again (though already available from the previous stage's withCredentials, this makes them explicitly available to envsubst).

APP_NAME: Set to java-gradle-app.

IMAGE_NAME: Set to the value of env.imageName (which is latest).

Executes shell commands (sh step):

Uses envsubst to substitute environment variables (like $APP_NAME, $IMAGE_NAME, $AWS_ECR_REPO if used in the YAML) into kubernetes/deployment.yaml and applies the result using kubectl apply -f -.

Does the same substitution and application process for kubernetes/service.yaml.

Has a 3-minute timeout.

How to Use

Ensure Prerequisites: Verify all items listed in the Prerequisites section are met.

Place Jenkinsfile: Add this Jenkinsfile-Shared-Library file to the root of your Java Gradle application's Git repository.

Add Kubernetes Manifests: Create the kubernetes/deployment.yaml and kubernetes/service.yaml files within your repository, ensuring they use environment variables for dynamic values (e.g., image: $AWS_ECR_REPO:$IMAGE_NAME).

Create Jenkins Job:

In Jenkins, create a new Pipeline job (or Multibranch Pipeline if appropriate).

Configure the job's SCM section to point to your Git repository.

Ensure the "Script Path" is set to Jenkinsfile-Shared-Library (or the correct filename if you renamed it).

Save the job configuration.

Run Pipeline: Trigger the Jenkins job manually or configure it to trigger automatically (e.g., on code pushes).

Kubernetes Manifests (kubernetes/)

This pipeline expects Kubernetes manifest files (deployment.yaml, service.yaml) to be present in a kubernetes/ directory at the root of the repository.

The deploy stage uses envsubst to replace variables in these files before applying them. Make sure your YAML files use the correct variable syntax (e.g., $VARIABLE_NAME or ${VARIABLE_NAME}) for values that need to be substituted at deploy time.

Example deployment.yaml snippet:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: $APP_NAME # Will be substituted
spec:
  replicas: 2
  selector:
    matchLabels:
      app: $APP_NAME # Will be substituted
  template:
    metadata:
      labels:
        app: $APP_NAME # Will be substituted
    spec:
      containers:
      - name: $APP_NAME # Will be substituted
        image: $AWS_ECR_REPO:$IMAGE_NAME # Will be substituted
        ports:
        - containerPort: 8080
IGNORE_WHEN_COPYING_START
content_copy
download
Use code with caution.
Yaml
IGNORE_WHEN_COPYING_END
Troubleshooting

Shared Library Fetch Error: Check Jenkins credentials (GitHub ID) and network connectivity to GitHub. Ensure the repository URL is correct.

Gradle Tool Not Found: Verify the Gradle tool named Gradle 7.6.1 is configured correctly in Jenkins Global Tool Configuration.

ECR Authentication Error: Ensure the AWS credentials (jenkins_aws_access_key_id, jenkins_aws_secret_access_key) have the necessary ecr:GetAuthorizationToken and push permissions. Check the region.

aws eks update-kubeconfig Failure: Verify the AWS credentials have eks:DescribeCluster permission for demo-cluster-3 in ap-south-1. Check if the cluster exists and the name/region are correct.

kubectl Errors: Ensure kubectl is installed on the agent and the kubeconfig is correctly updated. Check EKS RBAC permissions for the AWS credentials used.

envsubst: command not found: Install the gettext package (or equivalent) on the Jenkins agent.

