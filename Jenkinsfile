pipeline {
    agent any 
    tools {
        gradle "Gradle"
    }
    stages{
        stage("Build Jar"){
            steps{
                sh "./gradlew clean build"
                echo "Building the application..."
            }
        stage ("Build Docker Image") {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "docker build -t kalki2878/java-gradle-app:latest . "
                        sh "docker login -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}"
                        sh "echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USERNAME} --password-stdin"
                        sh "docker push kalki2878/java-gradle-app:latest"
                    }
                    echo "Building the Docker image..."
                }
            }
        }
        stage ("Deploy") {
            steps {
                script {
                    echo "Deploying the application..."
                }
            }
        }
    }
}
