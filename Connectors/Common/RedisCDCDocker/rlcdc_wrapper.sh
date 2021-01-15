#!/bin/sh
set -e

echo -------------------------------
export CLASSPATH="../lib/*"
export IVOYANT_CDC_CONFIG=../config/samples
export LOGBACK_CONFIG=../config/logback.xml

echo
echo "# arguments called with ---->  ${@}     "
echo "# \$1 ----------------------->  $1      "
echo "# \$2 ----------------------->  $2      "
echo "# \$3 ----------------------->  $3      "
echo "# path to me --------------->  ${0}     "
echo "# parent path -------------->  ${0%/*}  "
echo "# my name ------------------>  ${0##*/} "
echo

if [ -z $1 ] || [ -z $2 ] ; then
        echo "Missing arguments. Exiting.."
        echo "Usage: ${0##*/} create cdc|loader OR start cdc|loader true|false" 
        exit 0
fi

if [ "$1" = "create" ] && [ "$2" = "cdc" ]
then
	echo "Running cleanup and create to seed RedisCDC job management database"
	echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/cdc"
	export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/cdc
        java -classpath "../lib/*" -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.connector.redis.CDCSetup cleanup
        java -classpath "../lib/*" -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.connector.redis.CDCSetup create
elif [ "$1" = "create" ] && [ "$2" = "loader" ]
then
        echo "Running cleanup and create to seed RedisCDC job management database"
        echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/loader"
        export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/loader
        java -classpath "../lib/*" -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.connector.redis.CDCSetup cleanup
        java -classpath "../lib/*" -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.connector.redis.CDCSetup create
elif [ "$1" = "start" ] && [ "$2" = "cdc" ]
then
        if [ "$#" -ne 3 ]
        then
	        echo "No argument supplied, Job Management will be disabled by default , atleast one agent should have JobManagement enabled"
                echo -------------------------------
                echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/cdc"
                export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/cdc
                java -classpath "../lib/*" -Divoyant.cdc.jobManagement.enabled=$3 -Dlogback.configurationFile=$LOGBACK_CONFIG -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.CDCMain
        fi

        if [ "$#" -eq 3 ]
        then
                if [ $3 = "true" ]
                then
                       echo "Job Management will be enabled on this instance"
                else
                       echo "Job Management is disabled on this instance , atleast one agent should have JobManagement enabled"
                fi
        echo -------------------------------
        echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/cdc"
        export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/cdc
        java -classpath "../lib/*" -Divoyant.cdc.jobManagement.enabled=$3 -Dlogback.configurationFile=$LOGBACK_CONFIG -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.CDCMain
        fi
elif [ "$1" = "start" ] && [ "$2" = "loader" ]
then
        if [ "$#" -ne 3 ]
        then
	        echo "No argument supplied, Job Management will be disabled by default , atleast one agent should have JobManagement enabled"
                echo -------------------------------
                echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/loader"
                export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/loader
                java -classpath "../lib/*" -Divoyant.cdc.jobManagement.enabled=$3 -Dlogback.configurationFile=$LOGBACK_CONFIG -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.CDCMain
        fi

        if [ "$#" -eq 3 ]
        then
                if [ $3 = "true" ]
                then
                       echo "Job Management will be enabled on this instance"
                else
                       echo "Job Management is disabled on this instance , atleast one agent should have JobManagement enabled"
                fi
        echo -------------------------------
        echo "Using job configurations from ${IVOYANT_CDC_CONFIG}/loader"
        export IVOYANT_CDC_CONFIG=${IVOYANT_CDC_CONFIG}/loader
        java -classpath "../lib/*" -Divoyant.cdc.jobManagement.enabled=$3 -Dlogback.configurationFile=$LOGBACK_CONFIG -Divoyant.cdc.configLocation=$IVOYANT_CDC_CONFIG com.ivoyant.cdc.CDCMain
        fi
else
	echo "Invalid argument supplied"
	echo "Usage: ${0##*/} create cdc|loader OR start cdc|loader true|false"
	exit 0
fi
