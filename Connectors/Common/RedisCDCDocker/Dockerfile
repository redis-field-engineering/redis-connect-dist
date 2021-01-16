# This image is maintained by the OpenJDK team, and contains everything we need to run a Java 8 application within a Docker container
FROM openjdk:8-jre
LABEL maintainer="virag@redislabs.com"
ARG BUILDVERSION
ARG VERSION
ARG CONNECTOR
ENV CONNECTOR=$CONNECTOR

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
RUN chmod a+x /opt/redislabs/${CONNECTOR}/bin/rlcdc_wrapper.sh

# Create a temp script to pass the $CONNECTOR env to entrypoint
RUN echo "/opt/redislabs/$CONNECTOR/bin/rlcdc_wrapper.sh \$@" > /run_rlcdc_wrapper.sh
ENTRYPOINT ["/bin/bash", "/run_rlcdc_wrapper.sh"]

RUN echo "Successfully built RedisCDC ${CONNECTOR} v${VERSION} container."
