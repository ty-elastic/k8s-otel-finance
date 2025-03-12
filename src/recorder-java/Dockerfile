FROM maven:3-eclipse-temurin-17 AS build  
COPY src /usr/src/app/src  
COPY pom.xml /usr/src/app
WORKDIR /usr/src/app
RUN mvn package -Dmaven.test.skip

FROM eclipse-temurin:17

COPY --from=build /usr/src/app/target/recorder-0.0.1-SNAPSHOT.jar /recorder.jar

EXPOSE 9003
ENTRYPOINT ["java", \
"-jar", "/recorder.jar"]
