def gv

// This pipeline defines the CI/CD process including initialization, building, and deployment from external script.groovy
pipeline {
    agent any 
    tools {
        gradle "Gradle"
    }
    stages {
        stage("Init") {
            steps {
                script {
                    gv = load "script.groovy"
                }
            }
        }
        stage("Build Jar") {
            steps {
                script {
                    gv.buildJar()
                }
            }
        }
        stage("Build Docker Image") {
            steps {
                script {
                    gv.buildImage()
                }
            }
        }
        stage("Deploy") {
            steps {
                script {
                    gv.deployApp()
                }
            }
        }
    }
}

