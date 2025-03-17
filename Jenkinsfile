pipeline {
    agent any
    tools {
        jdk "jdk-installer"
        gradle "Gradle"
    }
    environment {
        SHOW_GRADLE_VERSION = "false"
        docker_repository_name = "maven-snapshots"
        SERVER_URL = "localhost"
        PORT_NO = "8081"
    }
    stages {
        stage('Build') {
            steps {
                script {
                    sh "echo 'Starting the build process...'"
                    // Check the Gradle version to ensure the correct version is being used
                    if (env.SHOW_GRADLE_VERSION == 'true') {
                        sh "gradle --version"
                    }
                    sh "./gradlew clean build"
                }
            }
        }
        stage("Publish to Nexus") {
            steps {
                script {
                    // Using Nexus credentials to authenticate and upload build artifacts to the Nexus Repository Manager
                    withCredentials([usernamePassword(credentialsId: 'nexus-credentials', passwordVariable: 'NEXUS_PASSWORD', usernameVariable: 'NEXUS_USERNAME')]) {
                        sh "echo 'Uploading the build artifacts to Nexus Repository Manager...'"
                        sh "./gradlew publish"
                        sh "curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} -X GET \"http://${SERVER_URL}:${PORT_NO}/service/rest/v1/components?repository=${docker_repository_name}\""
                    }
                }
            }
        }
    }
}

