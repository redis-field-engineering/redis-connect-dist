FROM azul/zulu-openjdk-alpine:11
LABEL maintainer="virag@redis.com"
RUN apk update && apk add --no-cache --upgrade apk-tools bash wget unzip procps

ARG BUILDVERSION
ARG VERSION
ARG CONNECTOR
ENV CONNECTOR=$CONNECTOR
ENV VERSION=$VERSION
ENV BUILDVERSION=$BUILDVERSION
ENV PS1="\e[1;31m\u@\h> \e[m"
ENV REDISCONNECT_OS_ENV="container"
ENV REDISCONNECT_HOME=/opt/redislabs/${CONNECTOR}
ENV REDISCONNECT_JOB_MANAGER_CONFIG_PATH=$REDISCONNECT_HOME/config/jobmanager.properties
ENV REDISCONNECT_LOGBACK_CONFIG=$REDISCONNECT_HOME/config/logback.xml
ENV REDISCONNECT_LOGBACK_CLI_CONFIG=$REDISCONNECT_HOME/config/logback-cli.xml
ENV REDISCONNECT_JAVA_OPTIONS="-XX:+HeapDumpOnOutOfMemoryError -Xms1g -Xmx2g"
ENV REDISCONNECT_EXTLIB_DIR=$REDISCONNECT_HOME/extlib
ENV REDISCONNECT_LIB_DIR=$REDISCONNECT_HOME/lib/*:$REDISCONNECT_EXTLIB_DIR/*

WORKDIR ${REDISCONNECT_HOME}/
RUN pwd

RUN mkdir -p ${REDISCONNECT_HOME}/bin && \
    mkdir -p ${REDISCONNECT_HOME}/config && \
    mkdir -p ${REDISCONNECT_HOME}/extlib && \
    mkdir -p ${REDISCONNECT_HOME}/logs && \
    mkdir -p ${REDISCONNECT_HOME}/lib && \
    chmod a+w ${REDISCONNECT_HOME}/logs

COPY ./bin/redisconnect* ${REDISCONNECT_HOME}/bin/
COPY ./config/ ${REDISCONNECT_HOME}/config/
COPY ./lib/ ${REDISCONNECT_HOME}/lib/

RUN chmod a+x ${REDISCONNECT_HOME}/bin/redisconnect.* && \
    chmod a+w ${REDISCONNECT_HOME}/extlib

# Create a temp script to pass the $CONNECTOR env to entrypoint
RUN echo "${REDISCONNECT_HOME}/bin/redisconnect.sh \$@" > /redisconnect.sh
ENTRYPOINT ["/bin/bash", "/redisconnect.sh"]

RUN echo "Successfully built ${CONNECTOR} v${VERSION} container."
