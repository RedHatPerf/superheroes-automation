# Project Leyden: Production-Ready Training Workflow

Based on the presentation *"[Project Leyden's AOT - Shifting Java Startup into High Gear](https://www.youtube.com/watch?v=Oo96adJirPw)"*.

## Overview

This changes implements a **production-ready workflow** for optimizing Java application startup and warmup performance using checkpoint/restore technology. The approach is designed for real-world deployment scenarios where customers can train their applications once and deploy optimized artifacts to production.

## Core Performance Metrics

Project Leyden focuses on improving two critical performance aspects:

* **Startup**: Time to reach the first useful unit of work
* **Warmup**: Time to achieve peak performance

## Production Workflow

### The Three-Phase Model

This implementation provides a complete production workflow with three distinct execution phases:

#### 1. STANDARD Phase
Baseline execution without any optimization artifacts. Used for:
- Initial performance benchmarking
- Establishing baseline metrics
- Development and testing

#### 2. TRAINING Phase
Captures application behavior and generates optimization artifacts for production use:
1. Application executes under realistic workload
2. Load generator exercises critical code paths
3. Optimization artifacts are captured and stored in `/app/checkpoint/` directory
4. Artifacts include JVM-specific optimization metadata

#### 3. OPTIMIZED Phase
Production deployment using pre-generated artifacts:
- Reuse builds from TRAINING Phase simulating a production workflow
- Application restores from checkpoint with optimization artifacts
- Achieves peak performance immediately on startup
- Eliminates warmup time in production

### Supported JVM Implementations

The workflow currently supports two production-ready JVM implementations:

#### Eclipse OpenJ9 21 (Semeru)
Uses CRIU-based checkpoint/restore technology:
- **Training**: `-XX:CRaCCheckpointTo=/app/checkpoint`
- **Optimized**: `-XX:CRaCRestoreFrom=/app/checkpoint`
- Configuration: [`semeru21.build.script.yaml`](modes/semeru21.build.script.yaml)

#### OpenJDK 25 (Temurin)
Uses JEP 514 AOT Cache technology:
- **Training**: `-XX:AOTCacheOutput=/app/checkpoint/app.aot`
- **Optimized**: `-XX:AOTCache=/app/checkpoint/app.aot -XX:AOTMode=on`
- Configuration: [`temurin25.build.script.yaml`](modes/temurin25.build.script.yaml)

## Production Deployment Strategy

### Artifact Management

All optimization artifacts are stored in a dedicated checkpoint directory:
- **Location**: `/app/checkpoint/`
- **Persistence**: Artifacts can be extracted and deployed to production containers
- **Portability**: Artifacts are JVM-implementation specific but environment-independent

### Container Architecture

The implementation uses parameterized Dockerfiles for flexibility:
- Base images specified via `ARG BASE_IMAGE`
- Unified [`start-quarkus.sh`](modes/assets/start-quarkus.sh) script handles all phases
- Checkpoint directory pre-created in container image

## Usage Examples

### Standard Execution

Baseline run using OpenJDK:
```bash
./run.sh jvm get-all-heroes hyperfoil local
```

### Training Phase

Generate optimization artifacts for production:

**Eclipse OpenJ9 21:**
```bash
./run.sh semeru21.build get-all-heroes hyperfoil local "-S PHASE=TRAINING"
```

**OpenJDK 25:**
```bash
./run.sh temurin25.build get-all-heroes hyperfoil local "-S PHASE=TRAINING"
```

### Optimized Production Deployment

Deploy with pre-generated artifacts:

**Eclipse OpenJ9 21:**
```bash
./run.sh semeru21.build get-all-heroes hyperfoil local "-S PHASE=OPTIMIZED"
```

**OpenJDK 25:**
```bash
./run.sh temurin25.build get-all-heroes hyperfoil local "-S PHASE=OPTIMIZED"
```

## Implementation Details

### Phase Configuration

The phase is controlled via the `PHASE` state variable in `superheroes.yaml`:
- Automatically configures JVM arguments based on selected phase
- JVM-specific parameters injected via `prepare-superheroes-sut` script
- Supports dynamic switching between phases without code changes

### Peak Performance Definition

**Current Approach**: Peak performance is defined as running the benchmark for a predetermined duration that allows the JVM to reach steady-state.

**Future Enhancement**: Statistical approach to detect performance stability (low variance over time) for more precise artifact generation.

## Considerations

### Validation
After training, the workflow validates that:
1. Artifacts are successfully generated
2. Application restores correctly from checkpoint

## Roadmap

- [ ] Extend checkpoint support to all services (fights, locations, villains)
- [ ] Add JIT Server optimization for heroes service
- [ ] Implement statistical peak performance detection

## References

- [Project Leyden Presentation](https://www.youtube.com/watch?v=Oo96adJirPw)
- [JEP 514: AOT Cache](https://openjdk.org/jeps/514)
- [Eclipse OpenJ9 CRIU Support](https://www.eclipse.org/openj9/docs/criusupport/)
