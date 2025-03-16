FROM openjdk:8-jre-alpine

WORKDIR /usr/app

COPY ./build/libs/java-gradle-project-1.0-SNAPSHOT.jar /usr/app

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "java-gradle-project-1.0-SNAPSHOT.jar"]

