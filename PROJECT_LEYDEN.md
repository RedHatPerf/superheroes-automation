# Project Leyden: Performance Definitions & Training Workflow

Based on the presentation *"P[roject Leyden's AOT - Shifting Java Startup into High Gear](https://www.youtube.com/watch?v=Oo96adJirPw)"*.

## Phases

### **Core Performance Metrics**

Project Leyden is about improving the *startup* and *warmup* of Java applications.

* **Startup**
  Defined as the time it takes to get to the first useful unit of work.

* **Warmup**
  Defined as the time it takes for the application to reach peak performance.

### **The Training Run**

*Note: This concept is different from the presentation. The presentation is suggesting from observing a production workload or creating an integration test.*

*Note: This definition outlines a specific checkpoint-based workflow for generating and utilizing optimization artifacts.*

A **Training Run** is a preparatory execution phase used to capture the application's behavior and state before production deployment. This process follows a cyclical validation pattern:

1. **Initial Warmup:** A load generator executes a benchmark against the application for a specified duration to exercise code paths.
2. **Artifact Generation:** The application state is captured, and a checkpoint (containing optimization artifacts and heap state) is stored.
3. **Restoration:** The application is restored from the saved checkpoint (utilizing the stored artifacts).
4. **Validation:** The load generator runs the benchmark again against the restored application to ensure peak performance is achieved immediately.

## Experiment

### Objective
The goal of this experiment is to execute training runs that capture specific optimization artifacts and validate the performance of the restored application.

### 1. Defining Peak Performance
* **Current Approach:** For the scope of this experiment, "reaching peak performance" is defined as running the benchmark for a fixed, predetermined amount of time.
* **Future Optimization:** Future iterations may adopt a statistical approach, identifying peak performance when the system achieves stability (low variance) while executing the same operation over some time.

### 2. Artifact Management
* **Storage Location:** All optimization artifacts (e.g., heap snapshots, profile data) will be stored in a dedicated `cr` (Checkpoint/Restore) directory.
* **JVM Configuration:** Each specific JVM implementation must provide the necessary command-line parameters to collect these artifacts and direct them to the `cr` folder.

### 3. Restoration and Validation
* **Restoration:** The benchmark is re-executed by restoring the application state from the previously saved checkpoint.
* **Configuration:** As with storage, each JVM implementation must provide the specific arguments required to restore the application from the artifacts located in the `cr` folder.

### 4. Design Philosophy
This approach maintains the simplicity of the benchmark by supporting three distinct execution modes via argument injection:
* **Standard:** Run without arguments (baseline execution).
* **Training:** Run with parameters to **store** artifacts.
* **Optimized:** Run with parameters to **restore** from artifacts.

## Examples

**Standard** run using OpenJDK
```bash
./run.sh jvm get-all-heroes hyperfoil local
```

**Standard** run using Eclipse OpenJ9
```bash
./run.sh semeru.build get-all-heroes hyperfoil local
```

**Training** run using Eclipse OpenJ9
```bash
./run.sh semeru.build get-all-heroes hyperfoil local
```

## TODO List
* Fix training run example in PROJECT_LEYDEN.md (line 67 - currently identical to standard)
* Address root user security issue (USER 185) - modes/assets/semeru/Dockerfile.heroes.semeru
* Add checkpoint support for villains, locations, fights services
* Implement restore/optimized phase
* Add error handling for checkpoint failures
* Add back JIT Server. It should be optimal.
* Test end-to-end checkpoint/restore workflow
* Add validation step after restore
* Document CRIU configuration options (shell-job, ext-unix-sk)
