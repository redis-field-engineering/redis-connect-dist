FROM openjdk:8u275-jre
MAINTAINER Virag Tripathi <virag@redislabs.com>
ARG BUILDVERSION
ARG VERSION
ARG CONNECTOR

RUN apt-get update
RUN apt-get install -y unzip wget

RUN wget https://github.com/RedisLabs-Field-Engineering/RedisCDC/releases/download/v${VERSION}/${CONNECTOR}-${BUILDVERSION}.tar.gz && \
mkdir -p /opt/redislabs && \
mv ${CONNECTOR}-${BUILDVERSION}.tar.gz /opt/redislabs
RUN cd /opt/redislabs/ && \
tar -xvf ${CONNECTOR}-${BUILDVERSION}.tar.gz && \
rm ${CONNECTOR}-${BUILDVERSION}.tar.gz

WORKDIR /opt/redislabs/${CONNECTOR}/bin/
RUN pwd

COPY ./rlcdc_wrapper.sh /opt/redislabs/${CONNECTOR}/bin/
RUN chmod 755 /opt/redislabs/${CONNECTOR}/bin/rlcdc_wrapper.sh

ENTRYPOINT ["sh", "/opt/redislabs/rl-connector-rdb/bin/rlcdc_wrapper.sh"]
