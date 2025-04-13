#!/usr/bin/env groovy

library identifier: 'devops-shared-lib@master', retriever: modernSCM(
    [
        $class: 'GitSCMSource',
        remote: 'https://github.com/TheSudheer/Jenkins-shared-library.git',
        credentialsId: 'GitHub'
    ]
)

pipeline {
    agent any
    tools {
        gradle 'Gradle 7.6.1'
    }
    options {
        timeout(time: 10, unit: 'MINUTES')
    }
    environment {
        imageName = "kalki2878/java-gradle-app:latest"
    }
    stages {
        stage("build jar") {
            steps {
                script {
                    echo "build jar file"
                    timeout(time: 3, unit: 'MINUTES') {
                    // This piece of code was written using the jenkins-shared-library from:
                    // https://github.com/TheSudheer/Jenkins-shared-library.git
                        buildJar()
                    }
                    echo "Finished build jar stage"
                }
            }
        }
        stage("build image") {
            steps {
                script {
                    echo "Starting build image stage"
                    timeout(time: 3, unit: 'MINUTES') {
                        buildImage.groovy(env.imageName)
                    // This piece of code was written using the jenkins-shared-library from:
                    // https://github.com/TheSudheer/Jenkins-shared-library.git
                    }
                    echo "Finished build image stage"
                }
            }
        }
        stage ("Provision Server") {
            environment {
                AWS_ACCESS_KEY_ID = credentials("jenkins_aws_access_key_id")
                AWS_SECRET_ACCESS_KEY = credentials("jenkins_aws_secret_access_key")
                TF_VAR_env_prefix = "test"
            }
            steps {
                script {
                    dir ("terraform") {
                        sh "terraform init"
                        sh "terraform apply --auto-approve"
                        ec2_Public_IP = (sh 
                        script: "terrafrom output ec2_public_ip"
                        returnStdout: true
                        ).trim()
                    }
                }
            }
        }
        stage("Deploy") {
            environment {
                DOCKER_CREDS = credentials("docker-hub-credentials")
            }
            steps {
                script {
                    echo "Waiting for ec2-server to initialize"

                    sleep (time: 90, unit: "SECONDS" ) 

                    echo "${ec2_Public_IP}"

                    echo 'Deploying docker image to EC2 using Docker Compose...'

                    // Define the shell command to execute our script on EC2
                    def shellCmd = "bash ./server-cmds.sh ${imageName} ${DOCKER_CREDS_USR} ${DOCKER_CREDS_PSW}"
                    def ec2IP = "ubuntu@${ec2_Public_IP}"
                    
                    sshagent(['ec2-server-key']) {
                        // List files to verify the docker-compose file is in the workspace.
                        sh "ls -l"
                        // Copy the version-controlled docker-compose.yml file and server-cmds.sh to the remote EC2 instance.
                        sh "scp -o StrictHostKeyChecking=no docker-compose.yml ${ec2IP}:/home/ubuntu"
                        sh "scp -o StrictHostKeyChecking=no server-cmds.sh ${ec2IP}:/home/ubuntu"
                        // SSH into the remote EC2 instance and execute the shell command.
                        sh "ssh -o StrictHostKeyChecking=no ${ec2IP} '${shellCmd}'"
                    }
                    echo "Finished build image stage"
                }
            }
        }
    }
}

