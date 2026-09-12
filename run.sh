#!/bin/bash

# Run qdup scripts easily such that you don't have to care about which config files to provide

# Path to search for folders
CWD="$(dirname "$0")"
BASE_BENCHMARKS_FOLDER="${CWD}/benchmarks"
BASE_MODES_FOLDER="${CWD}/modes"
BASE_DRIVERS_FOLDER="${CWD}/drivers"

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 <native|jvm> <benchmark_folder> [driver] [local|remote] [benchmark_params]"
  exit 1
fi

# Validate image mode
MODE="$1"
if [ ! -f "$BASE_MODES_FOLDER/$MODE.script.yaml" ]; then
  echo "Error: Script file '$MODE.script.yaml' does not exist in $BASE_MODES_FOLDER."
  echo "Available modes are:"
  ls -1 $BASE_MODES_FOLDER/*.script.yaml
  exit 1
fi

# Validate benchmark
BENCHMARK_FOLDER="$2"
if [ ! -d "$BASE_BENCHMARKS_FOLDER/$BENCHMARK_FOLDER" ]; then
  echo "Error: Benchmark folder '$BENCHMARK_FOLDER' does not exist in $BASE_BENCHMARKS_FOLDER."
  echo "Available benchmarks are:"
  ls -1 $BASE_BENCHMARKS_FOLDER
  exit 1
fi

# Validate driver
if [ "$#" -ge 3 ]; then
  DRIVER="$3"
  if [ ! -f "$BASE_DRIVERS_FOLDER/$DRIVER.yaml" ]; then
    echo "Error: Driver script file '$DRIVER.yaml' does not exist in $BASE_DRIVERS_FOLDER."
    echo "Available drivers are:"
    ls -1 $BASE_DRIVERS_FOLDER/*.yaml
    exit 1
  fi
else
  # default is 'local' 
  DRIVER="hyperfoil"
fi

# Validate server setup
if [ "$#" -ge 4 ]; then
  LOCATION="$4"
  if [[ "$LOCATION" != "local" && "$LOCATION" != "remote" ]]; then
    echo "Error: Server location, if provided, must be either 'local' or 'remote'."
    exit 1
  fi
else
  # default is 'local' 
  LOCATION="local"
fi

# handle additional HF benchmark params
if [ "$#" -eq 5 ]; then
  ADDITIONAL_ARGS="$5"
else
  ADDITIONAL_ARGS=""
fi

echo Running benchmark with the following configuration:
echo "  > Mode:             $MODE"
echo "  > Benchmark:        $BENCHMARK_FOLDER"
echo "  > Driver:           $DRIVER"
echo "  > Server:           $LOCATION"
echo "  > Benchmark params: $BENCHMARK_PARAMS"

# Check if jbang is installed, otherwise use Java directly
LOG_FORMAT="-Dqdup.console.format=\"%d{HH:mm:ss.SSS} %-5p %m%n\" -Dqdup.run.console.format=\"%d{HH:mm:ss.SSS} [ %X{role}:%X{script}@%X{host} ] %-5p %m%n\""
if command -v jbang >/dev/null 2>&1; then
  QDUP_CMD="jbang $LOG_FORMAT qDup@hyperfoil -b report-output $ADDITIONAL_ARGS ${BASE_BENCHMARKS_FOLDER}/${BENCHMARK_FOLDER}/${BENCHMARK_FOLDER}.env.yaml envs/${LOCATION}.env.yaml modes/${MODE}.script.yaml"
else
  # Fallback leveraging the existing Jenkins environment variables, or defaults if running locally
  JAVA_BIN=${JAVA:-java}
  JAR_PATH=${QDUP_JAR:-/opt/tools/qDup.jar}
  QDUP_CMD="$JAVA_BIN $LOG_FORMAT -jar $JAR_PATH -b report-output $ADDITIONAL_ARGS ${BASE_BENCHMARKS_FOLDER}/${BENCHMARK_FOLDER}/${BENCHMARK_FOLDER}.env.yaml envs/${LOCATION}.env.yaml modes/${MODE}.script.yaml"
fi

# Special handling for custom jvm builds
if [ "$MODE" = "semeru21.build" ] || [ "$MODE" = "temurin25.build" ] || [ "$MODE" = "temurin26.build" ] || [ "$MODE" = "semeru26.build" ]; then
  QDUP_CMD="$QDUP_CMD modes/custom.jvm.build.script.yaml "
fi

QDUP_CMD="$QDUP_CMD profiling.yaml drivers/${DRIVER}.yaml superheroes.yaml util.yaml qdup.yaml"

echo Executing: "$QDUP_CMD"

eval $QDUP_CMD