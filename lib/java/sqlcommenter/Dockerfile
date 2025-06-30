FROM gradle:jdk17 AS BUILD

WORKDIR /work

COPY . .

RUN ./gradlew build -x test

FROM alpine:latest

COPY --from=build /work/build/libs/com-example-sqlcommentor-1.0.0-all.jar /lib/com-example-sqlcommentor.jar
