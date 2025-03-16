Below is an example of a complete `README.md` for your project:

---

```markdown
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

## Overview

This Java project leverages Spring Boot to build a web application. In addition to running the application, it includes a custom Gradle configuration for publishing the JAR artifact to a Nexus repository. The project demonstrates:

- Publishing configuration, including secure credential handling via `gradle.properties`.
- Allowing an insecure (HTTP) protocol in a controlled environment for personal projects.

## Features

- **Maven Publishing:** Configured to publish snapshots to a Nexus repository.
- **Gradle Build Automation:** Automated build and publish processes.

## Prerequisites

- **Java Development Kit (JDK):** Ensure you have JDK 17 (or higher) installed.
- **Gradle Wrapper:** The project includes a Gradle wrapper so you don’t need a separate Gradle installation.
- **Nexus Repository:** A Nexus instance (or any Maven repository) running at `http://localhost:8081/repository/maven-snapshots/` or update the URL as needed.

## Getting Started

1. **Clone the Repository:**

   ```sh
   git clone <repository-url>
   cd java-gradle-project
   ```

2. **Configure Repository Credentials:**

   Create or update the `gradle.properties` file in the project root with the following properties:

   ```properties
   repoUser=your-username
   repoPassword=your-password
   ```

## Build and Run

Build the project using the Gradle wrapper:

```sh
./gradlew build
```

Run the Spring Boot application with:

```sh
./gradlew bootRun
```

The compiled JAR file can be found in the `build/libs/` directory.

## Publishing the Artifact

This project uses the Maven Publishing plugin to publish the generated JAR to a Nexus repository.

1. **Ensure your Nexus repository is running.**

2. **Publish the Artifact:**

   ```sh
   ./gradlew publish
   ```

This command will publish the artifact named `java-gradle-project-1.0-SNAPSHOT.jar` (based on the version defined) to the configured Nexus repository.

### Note on Insecure Protocol

The Nexus repository URL uses HTTP (`http://localhost:8081`), which is an insecure protocol. To allow this in your Gradle configuration, the following property is set:

```groovy
allowInsecureProtocol = true
```

## Gradle Configuration Details

- **Plugins Used:**
  - **`java`:** For compiling Java source code.
  - **`org.springframework.boot`:** For Spring Boot support (version `2.2.2.RELEASE`).
  - **`io.spring.dependency-management`:** To manage dependency versions (version `1.0.8.RELEASE`).
  - **`maven-publish`:** For publishing artifacts to a Maven repository.

- **Project Settings:**
  - `group`: `com.example`
  - `version`: `1.0-SNAPSHOT`
  - `sourceCompatibility`: `1.8`

- **Artifact Configuration:**

  The artifact is declared with proper Groovy string interpolation to avoid misinterpretation:

  ```groovy
  artifact(file("build/libs/java-gradle-project-${version}.jar")) {
      extension = 'jar'
  }
  ```

- **Repository Credentials:**

  Credentials for publishing are securely stored in `gradle.properties` and retrieved during the build.

## Troubleshooting

- **Error: "No such property: jar for class: java.lang.String"**

  This error results from incorrect string interpolation in the artifact declaration. Make sure to wrap the variable in curly braces:

  ```groovy
  "build/libs/java-gradle-project-${version}.jar"
  ```

- **Insecure Protocol Issues:**

  If you encounter issues related to HTTP connections, ensure that `allowInsecureProtocol = true` is set in the repository configuration. In production, consider switching to an HTTPS endpoint.

## Proof of Nexus Repository

Below is a screenshot showing the Nexus repository after a successful publish:

![Nexus Repository Screenshot](home/sudheer/Screenshots/nexus-screenshot.png)


