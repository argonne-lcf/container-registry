# MPI on Polaris using Apptainer (Singularity)

This guide provides steps to build and run MPI applications on Polaris using Apptainer containers. It covers two main approaches:
1.  **Native MPI Mode:** Your MPI application is compiled on the host system using Polaris's native Cray MPICH. It then runs inside a basic container, dynamically linking to the host's MPI libraries. This is generally the recommended and most straightforward method.
2.  **Hybrid MPI Mode:** A specific version of MPICH is compiled inside the container. The application, also compiled inside the container, attempts to interface with the host's process management (PMI) and fabric libraries at runtime. This mode is more complex due to potential ABI incompatibilities but can be useful for specific MPICH versions or features not available on the host.

## Initial Setup (Common for Both Modes)

```bash
# Load necessary modules on Polaris
ml use /soft/modulefiles
ml spack-pe-base/0.8.1
ml use /soft/spack/testing/0.8.1/modulefiles
ml apptainer/main # Or singularity, if that's the command on your system
ml load e2fsprogs
module unload darshan
module unload xalt

# Do not need for Native MPI mode, and needed for Hybrid mode
# module load cray-mpich-abi

# Configure Apptainer temporary and cache directories (IMPORTANT for Polaris)
export BASE_SCRATCH_DIR=/local/scratch/ # Ensure this is a fast, local filesystem
export APPTAINER_TMPDIR=$BASE_SCRATCH_DIR/apptainer-tmpdir
mkdir -p $APPTAINER_TMPDIR
export APPTAINER_CACHEDIR=$BASE_SCRATCH_DIR/apptainer-cachedir/
mkdir -p $APPTAINER_CACHEDIR

# Proxy setup for internet access (if building containers that need to download files)
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
```

## Mode 1: Native MPI (Host-Compiled Application)

In this mode, you compile your MPI application directly on Polaris and run it within a generic container (e.g., a base Ubuntu or an NVIDIA CUDA container).

### 1. Compiling your MPI application on the Host

Use the system's `cc`, `CC`, or `ftn` wrappers, which are already configured for MPI.

**Example: C Hello World (`mpi_hello_host.c`)**
```c
// mpi_hello_host.c
#include <mpi.h>
#include <stdio.h>
#include <unistd.h> // For gethostname
#include <limits.h> // For HOST_NAME_MAX

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int world_rank, world_size;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);
    char hostname[HOST_NAME_MAX];
    gethostname(hostname, HOST_NAME_MAX);
    printf("Native Mode: Rank %d of %d on %s
", world_rank, world_size, hostname);
    MPI_Finalize();
    return 0;
}
```

Compile it:
```bash
cc mpi_hello_host.c -o mpi_hello_host
```

### 2. Running with a Generic Container

You'll need a base image. You can pull one or use an existing SIF file.
Example using NVIDIA's cuQuantum appliance (replace with your desired container if not using GPUs or cuQuantum):
```bash
apptainer pull docker://nvcr.io/nvidia/cuquantum-appliance:24.08-x86_64
CONTAINER=cuquantum-appliance_24.08-x86_64.sif
# Or any other base .sif, e.g., ubuntu.sif
```

**Execution Script (`run_native.sh`):**
Make sure your application (e.g., `mpi_hello_host`) is in the `$PWD` or provide the full path.
The `LD_LIBRARY_PATH` is set to include necessary Cray and NVIDIA libraries. The bind mounts provide access to system components.

```bash
#!/bin/bash
#PBS -l select=1:system=polaris
#PBS -q debug
#PBS -l place=scatter
#PBS -l walltime=0:10:00
#PBS -l filesystems=home:grand
#PBS -A YourProject

cd ${PBS_O_WORKDIR}

CONTAINER=cuquantum-appliance_24.08-x86_64.sif # Or your SIF file
MPI_EXECUTABLE=$PWD/mpi_hello_host # Path to your host-compiled MPI code

# Ensure modules from initial setup are loaded
# module load cray-mpich-abi (should be loaded already)

NODES=$(wc -l < $PBS_NODEFILE)
PPN=4 # Ranks per node
PROCS=$((NODES * PPN))

# Essential environment variables for Apptainer to find host MPI/Fabric libs
# The cray-mpich-abi module helps set CRAY_LD_LIBRARY_PATH
export APPTAINERENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH"
# You might need to add other paths if your application has other dependencies.
# e.g., /opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib for NVIDIA HPC SDK

echo "Running Native MPI: $MPI_EXECUTABLE with $PROCS ranks on $NODES nodes ($PPN PPN)"

mpiexec -np $PROCS -ppn $PPN \
    apptainer exec \
    -B $PWD \
    -B /opt/cray \
    -B /opt/nvidia \
    -B /usr/lib64:/hostlib64 \
    -B /var/run/palsd \
    --nv \
    $CONTAINER $MPI_EXECUTABLE
```
Submit with `qsub run_native.sh`.

## Mode 2: Hybrid MPI (Container-Compiled Application and MPI)

In this mode, MPICH (and your application) is compiled inside the Apptainer container. This requires careful setup to ensure the container's MPI can interoperate with Polaris's PMI and fabric.

### 1. Apptainer Definition File (`mpich.def`)

This definition file builds MPICH from source inside an Ubuntu container.
It's crucial to use the `build_mpich_3.4.3.sh` script if you intend to use `mpi4py`, as this version has shown compatibility. For C/C++ applications, newer MPICH versions (like 4.0.2, using `build_mpich_4.sh`) might also work, but `mpi4py` is sensitive.

**Key points in `mpich.def` and build script:**
*   Refer to `mpich.def` and the associated build script (e.g., `build_mpich_3.4.3.sh` or `build_mpich_4.sh`).
*   The MPICH configure flag `--disable-wrapper-rpath` is important as it prevents `mpicc` from hardcoding `RPATH`s, giving more flexibility for the dynamic linker at runtime.
*   The script also compiles any C/C++/Python code placed in the `source/` directory (copied to `/usr/source/` in the container).

**Example `mpich.def` (ensure it uses `build_mpich_3.4.3.sh` for `mpi4py`):**
```apptainer
bootstrap: docker
From: ubuntu:22.04

%environment
 export PATH=/mpich/install/bin:$PATH
 export LD_LIBRARY_PATH=/mpich/install/lib:$LD_LIBRARY_PATH
 # For Python 3.10 on Ubuntu 22.04; adjust if using a different Python version
 export PYTHONPATH=/usr/local/lib/python3.10/dist-packages:$PYTHONPATH

%files
 source/ /usr/source/              # Your C/Python source code
 build_mpich_3.4.3.sh /usr/       # Script to build MPICH 3.4.3

%post
 export DEBIAN_FRONTEND=noninteractive
 export http_proxy=http://proxy.alcf.anl.gov:3128  # Set proxy for build
 export https_proxy=http://proxy.alcf.anl.gov:3128

 apt-get update -y
 apt-get install -y --no-install-recommends build-essential libfabric-dev gfortran wget python3 python3-pip vim git
 ln -fs /usr/share/zoneinfo/America/Chicago /etc/localtime
 apt-get install -y tzdata
 dpkg-reconfigure --frontend noninteractive tzdata


 # Create directory for MPICH installation
 mkdir -p /mpich/install
 chmod +x /usr/build_mpich_3.4.3.sh
 /usr/build_mpich_3.4.3.sh # This script builds MPICH and compiles files in /usr/source

 echo "--- Installing mpi4py against container MPICH ---"
 # Ensure pip uses the MPICH built inside the container
 export MPICC=/mpich/install/bin/mpicc
 pip3 install --no-cache-dir mpi4py

 # Verify mpi4py installation and linked MPI library
 python3 -c "from mpi4py import MPI; print(f'mpi4py using MPI: {MPI.Get_library_version()}')"

 # Cleanup
 rm -rf /var/lib/apt/lists/*
 unset http_proxy https_proxy
```

**Ensure `build_mpich_3.4.3.sh` has executable permissions and contains:**
*   Download and compilation of MPICH 3.4.3.
*   Configure flags: `--prefix=/mpich/install --with-device=ch4:ofi --disable-wrapper-rpath --enable-shared FFLAGS='-O3 -fallow-argument-mismatch' FCFLAGS='-O3 -fallow-argument-mismatch' CFLAGS='-O3' CXXFLAGS='-O3'`
*   Compilation of your C/C++ application (e.g., `mpicc -o /usr/source/mpi_hello_world /usr/source/mpi_hello_world.c`).

### 2. Building the Container
```bash
apptainer build --fakeroot mpich_hybrid.sif mpich.def
```

### 3. Running in Hybrid Mode

This is where environment variables and bind mounts are critical. The goal is for the MPI application inside the container (linked against the container's MPICH) to use the host's PMI for process launching and the host's Libfabric for network communication.

**Environment Setup for Hybrid Mode:**
You must pass specific library paths from the host into the container's environment.
The `cray-mpich-abi` module is key here as it sets up `CRAY_LD_LIBRARY_PATH`.

```bash
# In your shell or submission script, BEFORE mpiexec:
# Load necessary modules on Polaris
ml use /soft/modulefiles
ml spack-pe-base/0.8.1
ml use /soft/spack/testing/0.8.1/modulefiles
ml apptainer/main # Or singularity, if that's the command on your system
ml load e2fsprogs
module unload darshan
module unload xalt

# needed for Native mode
module load cray-mpich-abi

# Configure Apptainer temporary and cache directories (IMPORTANT for Polaris)
export BASE_SCRATCH_DIR=/local/scratch/ # Ensure this is a fast, local filesystem
export APPTAINER_TMPDIR=$BASE_SCRATCH_DIR/apptainer-tmpdir
mkdir -p $APPTAINER_TMPDIR
export APPTAINER_CACHEDIR=$BASE_SCRATCH_DIR/apptainer-cachedir/
mkdir -p $APPTAINER_CACHEDIR

# Proxy setup for internet access (if building containers that need to download files)
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128

export APPTAINERENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:/opt/cray/pe/lib64:/opt/cray/pals/1.3.4/lib:/usr/lib64"
# The /usr/lib64 from host is often mapped to /hostlib64 in examples, ensure consistency.
# If you bind -B /usr/lib64:/hostlib64, then include /hostlib64 in APPTAINERENV_LD_LIBRARY_PATH.
# For simplicity here, we're assuming direct paths if not remapped in the -B flag.
```

**Verifying Library Linking (Optional Debugging Step):**
You can check if your containerized application is correctly linking to the *host's* MPI libraries (especially `libmpi.so.12` from Cray):
```bash
CONTAINER=mpich_hybrid.sif # Your built container

mpiexec -np 1 apptainer exec \
    --nv \
    -B $PWD \
    -B /opt/cray \
    -B /opt/nvidia \
    -B /usr/lib64 \
    -B /var/run/palsd \
    $CONTAINER ldd /usr/source/mpi_hello_world # Path to C app compiled in container
```
The output should show `libmpi.so.12` pointing to a path under `/opt/cray/pe/mpich/...`.

**Execution Script (`run_hybrid.sh`):**
This script runs either a C application or a Python (`mpi4py`) application.

```bash
#!/bin/bash
#PBS -l select=1:system=polaris
#PBS -q debug
#PBS -l place=scatter
#PBS -l walltime=0:10:00
#PBS -l filesystems=home:grand
#PBS -A YourProject

cd ${PBS_O_WORKDIR}

CONTAINER=mpich_hybrid.sif # Your SIF file built with mpich.def
C_APP_PATH=/usr/source/mpi_hello_world # Compiled in container
PYTHON_APP_PATH=/usr/source/mpi_hello_world.py # Copied to container

# Ensure modules from initial setup are loaded
# module load cray-mpich-abi (should be loaded already)

# In your shell or submission script, BEFORE mpiexec:
# Load necessary modules on Polaris
ml use /soft/modulefiles
ml spack-pe-base/0.8.1
ml use /soft/spack/testing/0.8.1/modulefiles
ml apptainer/main # Or singularity, if that's the command on your system
ml load e2fsprogs
module unload darshan
module unload xalt

# needed for Native mode
module load cray-mpich-abi

# Configure Apptainer temporary and cache directories (IMPORTANT for Polaris)
export BASE_SCRATCH_DIR=/local/scratch/ # Ensure this is a fast, local filesystem
export APPTAINER_TMPDIR=$BASE_SCRATCH_DIR/apptainer-tmpdir
mkdir -p $APPTAINER_TMPDIR
export APPTAINER_CACHEDIR=$BASE_SCRATCH_DIR/apptainer-cachedir/
mkdir -p $APPTAINER_CACHEDIR

# Proxy setup for internet access (if building containers that need to download files)
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128

export APPTAINERENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:/opt/cray/pe/lib64:/opt/cray/pals/1.3.4/lib:/usr/lib64"

NODES=$(wc -l < $PBS_NODEFILE)
PPN=4 # Ranks per node
PROCS=$((NODES * PPN))

# Critical: This APPTAINERENV_LD_LIBRARY_PATH is what allows the containerized
# application to find and use the HOST's MPI libraries for communication.
# It must include paths to Cray's MPICH, PMI, Libfabric, PALS, and potentially others.
# The cray-mpich-abi module sets CRAY_LD_LIBRARY_PATH.
export APPTAINERENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:/opt/cray/pe/lib64:/opt/cray/pals/1.3.4/lib:/usr/lib64"
# Note: /usr/lib64 is added directly. If you use -B /usr/lib64:/hostlib64, use /hostlib64 here.

echo "Running Hybrid MPI C app: $C_APP_PATH with $PROCS ranks on $NODES nodes ($PPN PPN)"
mpiexec -np $PROCS -ppn $PPN \
    apptainer exec \
    -B $PWD \
    -B /opt/cray \
    -B /opt/nvidia \
    -B /usr/lib64 \
    -B /var/run/palsd \
    --nv \
    $CONTAINER $C_APP_PATH

echo "Running Hybrid MPI Python app: $PYTHON_APP_PATH with $PROCS ranks on $NODES nodes ($PPN PPN)"
# For mpi4py, it's the same principle: mpi4py, running with the container's Python,
# should pick up the host MPI libraries via APPTAINERENV_LD_LIBRARY_PATH.
# The MPICH 3.4.3 built in the container is primarily for mpi4py's build/compile time linkage.
# At runtime, we want it to use the host's ABI-compatible MPI.
mpiexec -np $PROCS -ppn $PPN \
    apptainer exec \
    -B $PWD \
    -B /opt/cray \
    -B /opt/nvidia \
    -B /usr/lib64 \
    -B /var/run/palsd \
    --nv \
    $CONTAINER python3 $PYTHON_APP_PATH
```
Submit with `qsub run_hybrid.sh`.

**Important Considerations for Hybrid Mode:**
*   **MPI Version Matching:** While the goal is to use the host's MPI libraries at runtime, the MPICH version compiled *inside* the container (especially for `mpi4py`'s build process) needs to be compatible enough. MPICH 3.4.3 has been found to work for `mpi4py` in this scenario.
*   **PMI Interface:** The host `mpiexec` communicates with the `pmi_proxy` launched by Apptainer, which then talks to the PMI server on the system. This relies on the host's PMI libraries being correctly picked up.
*   **Libfabric:** Similar to PMI, the application inside the container needs to use the host's Libfabric for network communication. `APPTAINERENV_LD_LIBRARY_PATH` and bind mounts for `/opt/cray` are key.
*   **Debugging:** If you encounter "rank 0" issues or network errors:
    *   Double-check `APPTAINERENV_LD_LIBRARY_PATH`.
    *   Use `ldd` inside the container (as shown above) to verify library linkage.
    *   Ensure all necessary `/opt/cray/...` paths are bound and accessible.
    *   The `module load cray-mpich-abi` is crucial.

## Simplified `lolcow.def` Example
The `lolcow.def` file remains a good simple example for understanding the basic structure of a definition file.
```bash
apptainer build --fakeroot lolcow.sif lolcow.def
apptainer run lolcow.sif
```
To run it with MPI (though lolcow itself isn't an MPI app), you'd adapt the native or hybrid `mpiexec` commands, e.g.:
```bash
# This is just illustrative, lolcow doesn't use MPI
mpiexec -np 2 apptainer exec lolcow.sif /usr/games/cowsay "MPI Lolcow"
```
