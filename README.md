# Superheroes Load Test Automation
Automation for running quarkus superheroes benchmark load tests

## Prerequisites

TL;DR

Install `jbang` tool using `sdkman`.

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

Checkout the [installation guide](https://www.jbang.dev/documentation/guide/latest/installation.html) for more details on how you can install it, the suggested approach is by using [sdkman](https://sdkman.io/) - which is installed right away by the qDup script if not present already. 


## Run using script

There is a `run.sh` that aims to makes the superheroes app setup and benchmark execution easier.
It uses qDup under the hood, therefore be sure you have properly installed it in your machine (see [prerequisites](#prerequisites) for more details).

### Usage

```bash
$ ./run.sh
Usage: ./run.sh <native|jvm> <benchmark_folder> [local|remote] [benchmark_params]
```

* `<native|jvm|<custom>>`:  which superheroes images you'd like to use, either [`native`](/modes/native.script.yaml) or [`jvm`](/modes/jvm.script.yaml). Modes are extensible by creating a custom (`/modes/<custom>.script.yaml`).
* `<benchmark_folder>`:     which benchmark you'd like to run among those listed in [/benchmarks](/benchmarks/) folder.
* `[local|remote]`:         where you would like to start the services, either [`local`](/envs/local.env.yaml) to run on `localhost` or [`remote`](/envs/remote.env.yaml). Default is `local`.  **Please note:** for `remote` environments, the current user MUST have passwordless ssh access to any remote machines defined in `/envs/remote.env.yaml`.
* `[benchmark_params]`:     any additional Hyperfoil benchmark template param you want to override, this strictly depends on the HF benchmark definition. Default is empty string.

> [!NOTE]
> If you use `/envs/remote.env.yaml`, please ensure to override variables contained in it with your specific server hostanames

### Examples

#### Get all heroes locally

```bash
./run.sh native get-all-heroes local
```

#### Get all villains locally with 20s duration

```bash
./run.sh native get-all-villains local "-PDURATION=20s"
```

## Run directly using qDup

By default, the `run.sh` will print out the qDup command that it will execute such that you can always 
run the same directly without passing through the script.

```bash
jbang qDup@hyperfoil benchmarks/get-all-heroes/get-all-heroes.env.yaml envs/local.env.yaml modes/native.script.yaml util.yaml hyperfoil.yaml superheroes.yaml qdup.yaml
```

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