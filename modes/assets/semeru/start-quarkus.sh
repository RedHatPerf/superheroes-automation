#!/bin/bash

ENDPOINT=${1}

exec $JAVA_HOME/bin/java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar ${JAVA_APP_JAR}
