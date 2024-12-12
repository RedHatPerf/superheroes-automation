# Superheroes Load Test Automation
Automation for running quarkus superheroes benchmark load tests

## Prerequisites

### QDup
To run these scripts you need [qDup](https://github.com/Hyperfoil/qDup) that you can download directly from the GitHub repository:

```bash
wget https://github.com/Hyperfoil/qDup/releases/download/qDup-0.8.5/qDup-0.8.5-uber.jar
```

> [!NOTE]
> If you want to learn more on qDup, see its [user guide](https://github.com/Hyperfoil/qDup/blob/master/docs/userguide.adoc)


### Hyperfoil

The benchmark execution is performed using [Hyperfoil](https://github.com/Hyperfoil/Hyperfoil/) benchmarking tool executed through [jbang](https://www.jbang.dev/documentation/guide/latest)

Therefore, you must have `jbang` installed in your system. Checkout the [installation guide](https://www.jbang.dev/documentation/guide/latest/installation.html) or just let the qDup script install it.

> [!NOTE]
> Be aware that if you don't have jbang installed, the qdup script will try to install it using [sdkman](https://sdkman.io/)- which is installed right away if not present already.

## Run using script

There is a `run.sh` that aims to makes the superheroes app setup and benchmark execution easier.
It uses qDup under the hood, therefore be sure you have properly installed it in your machine (see [prerequisites](#prerequisites) for more details).

> [!NOTE]
> The script relies on the qDup to be available and its location exported in env variable `QDUP_JAR`

### Usage

```bash
$ ./run.sh
Usage: ./run.sh <native|jvm> <benchmark_folder> [local|remote] [benchmark_params]
```

* `<native|jvm>`:       which superheroes images you'd like to use, either [`native`](/modes/native.env.yaml) or [`jvm`](/modes/jvm.env.yaml).
* `<benchmark_folder>`: which benchmark you'd like to run among those listed in [/benchmarks](/benchmarks/) folder.
* `[local|remote]`:     where you would like to start the services, either [`local`](/envs/local.env.yaml) or [`remote`](/envs/remote.env.yaml). Default is `local`.
* `[benchmark_params]`: any additional Hyperfoil benchmark template param you want to override, this strictly depends on the HF benchmark definition. Default is empty string.

> [!NOTE]
> If you are willing to use `/envs/remote.env.yaml` be sure to override it in according to your servers

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
java -jar <qdup.jar> benchmarks/get-all-heroes/get-all-heroes.env.yaml envs/local.env.yaml modes/native.env.yaml util.yaml hyperfoil.yaml superheroes.yaml qdup.yaml
```

Some of those qDup config files are mandatory and cannot be removed:
- `util.yaml`
- `hyperfoil.yaml`
- `superheroes.yaml`
- `qdup.yaml`
- either `envs/local.env.yaml` or `envs/remote.env.yaml`
- either `modes/native.env.yaml` or `modes/jvm.env.yaml`
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