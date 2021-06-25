FROM gradle:4.7.0-jdk8-alpine AS build
COPY --chown=gradle:gradle *.gradle /home/gradle/src/
COPY --chown=gradle:gradle ./external/ /home/gradle/src/external/
COPY --chown=gradle:gradle ./src/ /home/gradle/src/src/
WORKDIR /home/gradle/src
RUN gradle allJars --no-daemon

RUN ls -l /home/gradle/src/*
RUN ls -l /home/gradle/src/build/libs/*

FROM openjdk:8-jre-slim

RUN mkdir /app

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    curl

COPY --from=build /home/gradle/src/build/libs/*.jar /app/sharedstreets-builder.jar

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
