#!/bin/bash

echo "----"
$JAVA_HOME/bin/java -version 2>&1
echo "----"

# Simplified Version Check (Optional, but kept for your logic)
JAVA_MAJOR_VERSION=$(java -XshowSettings:properties -version 2>&1 | grep "java.specification.version" | cut -d= -f2 | tr -d ' ' | sed 's/^1\.//')

echo "Detected Java Major Version: $JAVA_MAJOR_VERSION"

# Initialize JAVA_OPTS
if [ "$JAVA_MAJOR_VERSION" -eq 21 ]; then
  JAVA_OPTS="$JAVA_OPTS -XX:CRaCCheckpointTo=cr"
else
  echo "Found version '$JAVA_MAJOR_VERSION'. No custom shutdown function"
fi

echo "----"
echo "JAVA_OPTS=${JAVA_OPTS}"
echo "JAVA_OPTS_APPEND=${JAVA_OPTS_APPEND}"
echo "----"

mkdir -p cr

echo "Starting Java (PID will be stable)..."
echo "Redirecting logs to /deployments/app.log to prevent CRIU pipe errors."

# 1. exec: Replaces shell with Java (PID stability)
# 2. > app.log: Detaches stdout from Docker (Fixes err=-52)
exec $JAVA_HOME/bin/java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar ${JAVA_APP_JAR} > /deployments/app.log 2>&1
