#!/bin/bash

$JAVA_HOME/bin/java -version 2>&1

echo "----"
echo "JAVA_OPTS=${JAVA_OPTS}"
echo "JAVA_OPTS_APPEND=${JAVA_OPTS_APPEND}"
echo "----"

# 1. exec: Replaces shell with Java (PID stability)
# 2. > app.log: Detaches stdout from Docker (Fixes err=-52)
exec $JAVA_HOME/bin/java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar ${JAVA_APP_JAR} > /deployments/app.log 2>&1
