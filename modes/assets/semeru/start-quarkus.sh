#!/bin/bash

$JAVA_HOME/bin/java -version
echo "----"
echo "Files under: /app/checkpoint/"
ls /app/checkpoint/
echo "----"
echo "JAVA_OPTS=${JAVA_OPTS}"
echo "JAVA_OPTS_APPEND=${JAVA_OPTS_APPEND}"
echo "----"

# Burn PIDs to push the counter high - the restore phase must have an available PID
for i in {1..100}; do (exit 0); done
CHECK_PID=$(bash -c 'echo $$')
echo "Current PID counter is at approx: $CHECK_PID"
# The (...) forces a NEW process ID. if you use exec it won't use the new CHECK_PID
(exec $JAVA_HOME/bin/java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar ${JAVA_APP_JAR}) >> /deployments/app.log 2>&1 &
JAVA_PID=$!
echo "Application started with High PID: $JAVA_PID"
# Wait for it to finish (keeps the container alive)
wait $JAVA_PID
