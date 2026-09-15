#!/bin/sh
# Plain JVM entrypoint for custom JDK images (no CRIU/AOT).
# Honors JAVA_OPTS (override) and JAVA_OPTS_APPEND, mirroring run-java.sh behavior.
exec java ${JAVA_OPTS} ${JAVA_OPTS_APPEND} -jar /deployments/quarkus-run.jar
