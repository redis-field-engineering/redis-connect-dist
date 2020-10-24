FROM openjdk:8-jre-alpine
ARG VERSION
ARG CONNECTOR

RUN apk update
RUN apk add unzip wget

RUN wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/v${VERSION}/${CONNECTOR}.tar.gz
RUN tar -xvf ${CONNECTOR}.tar.gz
WORKDIR /${CONNECTOR}/bin/

CMD ["sh", "-c", "./cleansetup.sh"]
