# Superheroes Load Test Automation
Automation for running quarkus superheroes benchmark load tests

## Prerequisites

TL;DR

Install `jbang` tool using [mise](https://mise.jdx.dev/).

### QDup

The whole automation is implemented using [qDup](https://github.com/Hyperfoil/qDup), a tool that allows shell commands to be queued up across multiple servers to coordinate performance tests.

In this specific scenario, we will execute `qDup` by making use [jbang](https://www.jbang.dev/documentation/guide/latest) such that you don't have to care about installing Java or any other external dependency.

> [!NOTE]
> If you want to learn more on qDup, see its [user guide](https://github.com/Hyperfoil/qDup/blob/master/docs/userguide.adoc)


### Hyperfoil

The load testing is performed using [Hyperfoil](https://github.com/Hyperfoil/Hyperfoil/) benchmarking tool, a microservice-oriented distributed benchmark framework. It is executed through [jbang](https://www.jbang.dev/documentation/guide/latest) such that you don't have to care about downloading executables and any dependency.

> [!NOTE]
> If you want to learn more on Hyperfoil, see the [Hyperfoil website](https://hyperfoil.io).

### JBang

Therefore, the only required tool that you have to install is [jbang](https://www.jbang.dev/documentation/guide/latest). 

Checkout the [installation guide](https://www.jbang.dev/documentation/guide/latest/installation.html) for more details on how you can install it, the suggested approach is by using [mise](https://mise.jdx.dev/) - which is installed right away by the qDup script if not present already. 


## Run using script

There is a `run.sh` that aims to makes the superheroes app setup and benchmark execution easier.
It uses qDup under the hood, therefore be sure you have properly installed it in your machine (see [prerequisites](#prerequisites) for more details).

### Usage

```bash
$ ./run.sh
Usage: ./run.sh <native|jvm> <benchmark_folder> [hyperfoil|loop] [local|remote] [benchmark_params] [--java-version <mise-id>]
```

* `<native|jvm|<custom>>`:  which superheroes images you'd like to use, either [`native`](/modes/native.script.yaml) or [`jvm`](/modes/jvm.script.yaml). Modes are extensible by creating a custom (`/modes/<custom>.script.yaml`).
* `<benchmark_folder>`:     which benchmark you'd like to run among those listed in [/benchmarks](/benchmarks/) folder.
* `[local|remote]`:         where you would like to start the services, either [`local`](/envs/local.env.yaml) to run on `localhost` or [`remote`](/envs/remote.env.yaml). Default is `local`.  **Please note:** for `remote` environments, the current user MUST have passwordless ssh access to any remote machines defined in `/envs/remote.env.yaml`.
* `[additional_params]`:     any additional parameters you want to override. E.g. to override the default Hyperfoil benchmark templates parameters, '-S HF_BENCHMARK_PARAMS="-PDURATION=20s"'. This strictly depends on the HF benchmark definition. Default is empty string.
* `[--java-version]`:     host JDK (mise id, e.g. `temurin-25`) for the Maven toolchain in image-build modes that consume the `BUILD_JAVA_VERSION` state (`semeru.build`, `jdk26.build`, modes derived from [`custom.build.tmpl.yaml`](/modes/custom.build.tmpl.yaml)). It does not change the container runtime: `semeru.build` images stay Semeru-based with OpenJ9-only options, so a non-Semeru JDK there only affects the build, not what gets benchmarked. `custom.native.build` hardcodes its Mandrel JDK, and the prebuilt `native`/`jvm` modes ignore the flag (`run.sh` warns). May appear anywhere on the command line.
* `[--runtime-base-image]`: container base image providing the benchmarked JDK, for build modes that consume the `RUNTIME_BASE_IMAGE` state (currently `jdk26.build`, default `docker.io/library/eclipse-temurin:26-jdk`). Optional: when unset, the mode's default is used. Ignored by modes that don't build images (`run.sh` warns). May appear anywhere on the command line.

> [!NOTE]
> If you use `/envs/remote.env.yaml`, please ensure to override variables contained in it with your specific server hostanames

### Examples

#### Get all heroes locally

```bash
./run.sh native get-all-heroes hyperfoil local
```

#### Get all villains locally with 20s duration

```bash
./run.sh native get-all-villains hyperfoil local '-S HF_BENCHMARK_PARAMS="-PDURATION=20s"'
```

#### Build images with a specific host JDK and get all heroes locally

```bash
./run.sh temurin25.build get-all-heroes hyperfoil local '-S BUILD_JAVA_VERSION=temurin-25'
```

Note this selects the JDK running the Maven build; the benchmarked images are still the mode's own. `BUILD_JAVA_VERSION` is a [mise](https://mise.jdx.dev/) id (e.g. `temurin-25`, `semeru-openj9-21`, `mandrel-23.1`), installed on demand by [`core/core-install.script.yaml`](/core/core-install.script.yaml). The JDK baked into container base images is the separate `BASE_IMAGE_JAVA_VERSION` state (also a mise id, e.g. `temurin-25`). Any qDup state can be overridden directly with `-S NAME=value` in `[benchmark_params]`.

#### Build plain JVM images with a custom JDK and get all heroes locally

```bash
./run.sh temurin25.build get-all-heroes hyperfoil local
```

The `temurin25.build` mode (see [`modes/unified.build.script.yaml`](/modes/unified.build.script.yaml)) builds plain JVM images for benchmarking JDKs without official images. It accepts `-S BUILD_JAVA_VERSION=<mise-id>` (Maven toolchain) and `-S JAVA_OPTS_APPEND="..."` for runtime JVM flags. Use `-S SUPERHEROES_CUSTOM_TAG=<tag>` to keep images of different runtimes side by side.

#### Benchmark Temurin 27

```bash
./run.sh temurin27.build get-all-heroes hyperfoil local
```

#### Benchmark Semeru 21 (OpenJ9)

```bash
./run.sh semeru21.build get-all-heroes hyperfoil local
```

(`semeru26` is retired: Semeru 26 is not an LTS and sees no upstream investment. Semeru 25 remains available in the mise catalog should an LTS mode be needed.)

#### Set JVM flags for all services

Runtime JVM flags go through `-S JAVA_OPTS_APPEND="..."`, honored by both the prebuilt images (`run-java.sh`) and custom-built JVM images (`start-quarkus.sh`):

```bash
./run.sh temurin25.build get-all-heroes hyperfoil local '-S JAVA_OPTS_APPEND="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager -Xms2g -Xmx2g -XX:+UnlockExperimentalVMOptions -XX:+UseCompactObjectHeaders" -S HEROES_REST_MEMORY=3G'
```

Notes:
- `-S` *replaces* the `JAVA_OPTS_APPEND` default, so always restate the two base `-D` flags above.
- Pair heap size with container memory: `-Xmx2g` exceeds the default `--memory 1G` per service and gets OOMKilled. Per-service `HEROES/VILLAINS/LOCATIONS/FIGHTS_REST_MEMORY` and `*_CPU` states already exist (`get-all-heroes` needs only heroes).
- Flags supported by only one JDK (e.g. HotSpot-only compact headers on a Semeru runtime) abort the run by design: the JVM exits at startup, the readiness watch times out, and the cause is in `report-output/<timestamp>/sut/heroes.logs`. No compatibility matrix is maintained.

## Additional information

Some of those qDup config files are mandatory and cannot be removed:
- `util.yaml`
- `hyperfoil.yaml`
- `superheroes.yaml`
- `qdup.yaml`
- either `envs/local.env.yaml` or `envs/remote.env.yaml`
- either `modes/native.script.yaml`, `modes/jvm.script.yaml` or any custom script you want to implement
- one of `benchmarks/**/*.env.yaml`


## Add more benchmarks

New benchmark scenarios can be added under [/benchmarks](/benchmarks/) folder and the should match the following structure:

```bash
$ tree benchmarks/$BENCHMARK_NAME

benchmarks/get-all-heroes
├── $BENCHMARK_NAME.env.yaml
└── $BENCHMARK_NAME.hf.yaml

1 directory, 2 files
```

As an example:

```bash
$ tree benchmarks/get-all-heroes

benchmarks/get-all-heroes
├── get-all-heroes.env.yaml
└── get-all-heroes.hf.yaml

1 directory, 2 files
```

* `$BENCHMARK_NAME.env.yaml`: contains required qdup states/params to properly retrieve the benchmark definition
* `$BENCHMARK_NAME.hf.yaml`: contains the Hyperfoil benchmark definition

## Custom drivers

The automation is generic enough to let you setup your preferred load driver, by default we are providing the Hyperfoil one.

### How to setup a custom driver?

You can simply create your own qDup script under [`/drivers`](./drivers/) folder.
There are just a couple of things to be aware:
1. You need to implement the expected scripts (`setup-driver`, `run-benchmark`, `cleanup-driver`), see [driver template](./drivers/driver.tmpl.yaml) as base example.
2. If you want to have the profiling working you should ensure your driver raise the following signals:
   * `CONTAINERS_READY`: when all targeted application and telemetry containers are up and ready before the benchmark begins
   * `HF_BENCHMARK_STARTED`: when the profiling can be started
   * `HF_BENCHMARK_TERMINATED`: when the profiling can be stopped
   * `HF_STEADY_PHASE_STARTED`: (optional) when an additional profiling can be started
   * `HF_STEADY_PHASE_TERMINATED`: (optional) when an additional profiling can be stopped

## Custom builds

The automation is generic enough to let you build the superheroes services container images and run them instead of the currently available ones.

### How to build custom images?

Create a new qDup file under [modes](/modes/) directory, you can take as example the [custom.build.tmpl.yaml](/modes/custom.build.tmpl.yaml) template file using the following format `SCRIPT_IDENTIFIER.script.yaml`.

And then simply call the `run.sh` with your new qDup file instead of the defaults `native`/`jvm`, e.g.,
```bash
./run.sh SCRIPT_IDENTIFIER get-all-heroes local
```

> [!NOTE]
> As another example you can check [custom.native.script.yaml](/modes/custom.native.script.yaml) script file that contains some instructions to rebuild the native images keeping the debug file in the final container.

### How does it work?

The new qDup images file MUST provide an implementation for the `prepare-images` script and here you can do whatever you want in order to build the images the way you want.

```yaml
scripts:
  ...
  prepare-images:
  - log: building custom version of native images..
  - script: clone-superheroes
  ...
```

You just need to remember to override the superheroes images using `set-state`, e.g.,

```yaml
  - set-state: HEROES_REST_IMAGE "quay.io/quarkus-super-heroes/rest-heroes:${{SUPERHEROES_CUSTOM_TAG}}"
  - set-state: VILLAINS_REST_IMAGE "quay.io/quarkus-super-heroes/rest-villains:${{SUPERHEROES_CUSTOM_TAG}}"
  - set-state: LOCATIONS_GRPC_IMAGE "quay.io/quarkus-super-heroes/grpc-locations:${{SUPERHEROES_CUSTOM_TAG}}"
  - set-state: FIGHTS_REST_IMAGE "quay.io/quarkus-super-heroes/rest-fights:${{SUPERHEROES_CUSTOM_TAG}}"
```

> [!NOTE]
> If your images are already available somewhere you can simply override the images states without actually re-building anything.

## Report output
By default, qDup will generate the output withing the `report-output` folder
