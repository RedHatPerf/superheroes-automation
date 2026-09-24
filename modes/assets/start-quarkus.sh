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

# Define a cleanup function to gracefully terminate both the Java application and the background log stream
cleanup() {
    echo "Container stopping, sending SIGTERM to Java (PID: $JAVA_PID)..."
    kill -SIGTERM "$JAVA_PID"
    kill "$TAIL_PID" 2>/dev/null
    wait "$JAVA_PID"
    echo "Java process exited gracefully."
}

# Trap SIGTERM and SIGINT to run the cleanup function
trap 'cleanup' SIGTERM SIGINT

# Redirect standard output and error to a log file to ensure compatibility with Semeru CRIU.
# CRIU strictly monitors open file descriptors and will fail the checkpointing phase
# if the application remains directly attached to the container runtime's TTY or standard output streams.
# The (...) forces a NEW process ID to utilize the elevated CHECK_PID.
(exec $JAVA_HOME/bin/java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar ${JAVA_APP_JAR}) > /deployments/app.log 2>&1 &
JAVA_PID=$!

# Stream the log file contents to standard output to enable native container logging
touch /deployments/app.log
tail -f /deployments/app.log &
TAIL_PID=$!

echo "Application started with High PID: $JAVA_PID"
# Wait for the Java process to finish, which keeps the container alive
wait $JAVA_PID
