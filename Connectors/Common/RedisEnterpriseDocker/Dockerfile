FROM openjdk:8-jre-alpine
MAINTAINER Virag Tripathi <virag@redislabs.com>
ARG BUILDVERSION
ARG VERSION
ARG CONNECTOR

RUN apk update
RUN apk add unzip wget

RUN wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/v${VERSION}/${CONNECTOR}-${BUILDVERSION}.tar.gz && \
mkdir -p /opt/redislabs && \
mv ${CONNECTOR}-${BUILDVERSION}.tar.gz /opt/redislabs
RUN cd /opt/redislabs/ && \
tar -xvf ${CONNECTOR}-${BUILDVERSION}.tar.gz && \
rm ${CONNECTOR}-${BUILDVERSION}.tar.gz

WORKDIR /opt/redislabs/${CONNECTOR}/bin/
RUN pwd

COPY ./entrypoint.sh /opt/redislabs/
RUN chmod 755 /opt/redislabs/entrypoint.sh

ENTRYPOINT ["/opt/redislabs/entrypoint.sh"]
