# MPI on Polaris using Singularity
This guide provides steps to build and run a container using MPICH on Polaris. It also includes an example with CUDA-aware MPI for scaling on the A100 GPUs.

## Fetching an exisiting NVIDIA image

```bash
ml use /soft/modulefiles
ml spack-pe-base/0.8.1
ml use /soft/spack/testing/0.8.1/modulefiles
ml apptainer/main
ml load e2fsprogs
module unload darshan
module unload xalt
export BASE_SCRATCH_DIR=/local/scratch/ # FOR POLARIS
export APPTAINER_TMPDIR=$BASE_SCRATCH_DIR/apptainer-tmpdir
mkdir $APPTAINER_TMPDIR
export APPTAINER_CACHEDIR=$BASE_SCRATCH_DIR/apptainer-cachedir/
mkdir $APPTAINER_CACHEDIR

# Proxy setup for internet access
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128

# Example fetch of an nvidia container
apptainer pull docker://nvcr.io/nvidia/cuquantum-appliance:24.08-x86_64
```

## Compiling C code on host

```bash
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);
    printf("Hello from rank %d\n", world_rank);
    MPI_Finalize();
    return 0;
}

cc mpi_hello_world.c -o mpi_hello 
```

To compile C++ on host, see [example](https://github.com/argonne-lcf/GettingStarted/tree/master/ProgrammingModels/Polaris/CUDA/vecadd_mpi#compilation-with-nvidia-compilers)


## Running C code and python against container environment

```bash
CONTAINER=cuquantum-appliance_24.08-x86_64.sif 

# Run C Code
mpiexec -np 4 apptainer exec     -B $PWD     -B /opt/cray     -B /opt/nvidia/hpc_sdk -B /usr/lib64:/hostlib64  -B /var/run/palsd --env LD_LIBRARY_PATH=/opt/cray/pe/mpich/8.1.28/ofi/nvidia/23.3/lib:/opt/cray/libfabric/1.15.2.0/lib64:/opt/cray/pe/pmi/6.1.13/lib:/opt/cray/pals/1.3.4/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib:/hostlib64 --nv --fakeroot $CONTAINER $PWD/source/mpi_hello

# Run Python Code
mpiexec -np 4 apptainer exec     -B $PWD     -B /opt/cray     -B /opt/nvidia/hpc_sdk -B /usr/lib64:/hostlib64  -B /var/run/palsd --env LD_LIBRARY_PATH=/opt/cray/pe/mpich/8.1.28/ofi/nvidia/23.3/lib:/opt/cray/libfabric/1.15.2.0/lib64:/opt/cray/pe/pmi/6.1.13/lib:/opt/cray/pals/1.3.4/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib:/hostlib64 --nv --fakeroot $CONTAINER python3 $PWD/source/numba_hello_world.py
```
