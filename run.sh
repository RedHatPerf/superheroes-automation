#!/bin/bash

# Run qdup scripts easily such that you don't have to care about which config files to provide

# Path to search for folders
CWD="$(dirname "$0")"
BASE_BENCHMARKS_FOLDER="${CWD}/benchmarks"
BASE_MODES_FOLDER="${CWD}/modes"
BASE_DRIVERS_FOLDER="${CWD}/drivers"

# Extract optional flags (may appear anywhere) before positional handling.
# --java-version selects the host JDK (sdkman id, e.g. 25.0.4-tem) used by
# image-build modes via sdk-select-java. Prebuilt jvm/native images ignore it.
# --runtime-base-image selects the container base image (e.g. a JDK 26 image)
# used by image-build modes via the RUNTIME_BASE_IMAGE state. Optional: when
# unset, the mode's default base image is used.
JAVA_VERSION=""
RUNTIME_BASE_IMAGE=""
POSITIONAL=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --java-version)
      if [ -z "$2" ]; then
        echo "Error: --java-version requires a value, e.g. --java-version 25.0.4-tem"
        exit 1
      fi
      JAVA_VERSION="$2"
      shift 2
      ;;
    --java-version=*)
      JAVA_VERSION="${1#*=}"
      if [ -z "$JAVA_VERSION" ]; then
        echo "Error: --java-version requires a value, e.g. --java-version=25.0.4-tem"
        exit 1
      fi
      shift
      ;;
    --runtime-base-image)
      if [ -z "$2" ]; then
        echo "Error: --runtime-base-image requires a value, e.g. --runtime-base-image docker.io/library/eclipse-temurin:26-jdk"
        exit 1
      fi
      RUNTIME_BASE_IMAGE="$2"
      shift 2
      ;;
    --runtime-base-image=*)
      RUNTIME_BASE_IMAGE="${1#*=}"
      if [ -z "$RUNTIME_BASE_IMAGE" ]; then
        echo "Error: --runtime-base-image requires a value, e.g. --runtime-base-image=docker.io/library/eclipse-temurin:26-jdk"
        exit 1
      fi
      shift
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done
set -- "${POSITIONAL[@]}"

# Check if the correct number of arguments is provided
if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
  echo "Usage: $0 <native|jvm> <benchmark_folder> [driver] [local|remote] [benchmark_params] [--java-version <sdkman-id>] [--runtime-base-image <image>]"
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

# explicit flags win over any -S JAVA_VERSION/-S RUNTIME_BASE_IMAGE in benchmark_params
if [ -n "$JAVA_VERSION" ]; then
  ADDITIONAL_ARGS="$ADDITIONAL_ARGS -S JAVA_VERSION=$JAVA_VERSION"
fi
if [ -n "$RUNTIME_BASE_IMAGE" ]; then
  ADDITIONAL_ARGS="$ADDITIONAL_ARGS -S RUNTIME_BASE_IMAGE=$RUNTIME_BASE_IMAGE"
fi

# --java-version/--runtime-base-image only affect build modes that select a
# host JDK via sdk-select-java
if [ -n "$JAVA_VERSION$RUNTIME_BASE_IMAGE" ] && ! grep -q "sdk-select-java" "$BASE_MODES_FOLDER/$MODE.script.yaml"; then
  echo "Warning: --java-version/--runtime-base-image are ignored by the '$MODE' mode (it uses prebuilt images)." >&2
fi

echo Running benchmark with the following configuration:
echo "  > Mode:             $MODE"
echo "  > Benchmark:        $BENCHMARK_FOLDER"
echo "  > Driver:           $DRIVER"
echo "  > Server:           $LOCATION"
echo "  > Java version:     ${JAVA_VERSION:-(mode default)}"
echo "  > Runtime image:    ${RUNTIME_BASE_IMAGE:-(mode default)}"
echo "  > Benchmark params: $ADDITIONAL_ARGS"

QDUP_CMD="jbang qDup@hyperfoil -b report-output $ADDITIONAL_ARGS ${BASE_BENCHMARKS_FOLDER}/${BENCHMARK_FOLDER}/${BENCHMARK_FOLDER}.env.yaml envs/${LOCATION}.env.yaml modes/${MODE}.script.yaml profiling.yaml drivers/${DRIVER}.yaml superheroes.yaml util.yaml qdup.yaml"

echo Executing: "$QDUP_CMD"

eval $QDUP_CMD