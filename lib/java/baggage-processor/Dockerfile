FROM gradle:8 AS build  

WORKDIR /work

COPY gradle gradle
COPY build.gradle .
COPY gradle.properties .
COPY gradlew .
COPY gradlew.bat .
COPY settings.gradle .

RUN wget https://github.com/open-telemetry/opentelemetry-java-contrib/archive/refs/heads/main.zip
RUN unzip main.zip
RUN mv opentelemetry-java-contrib-main/baggage-processor/src src
RUN rm -rf main.zip
RUN rm -rf src/test

RUN ./gradlew build -x test

FROM alpine:latest

COPY --from=build /work/build/libs/io-opentelemetry-contrib-baggage-processor-1.0-all.jar /io-opentelemetry-contrib-baggage-processor.jar
