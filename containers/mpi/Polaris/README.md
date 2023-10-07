# MPI on Polaris using Singularity
This guide provides steps to build and run a container using MPICH on Polaris. It also includes an example with CUDA-aware MPI for scaling on the A100 GPUs.

# Building a mpich image on Polaris
To create an MPICH image on Polaris, first secure a compute node in interactive mode as demonstrated below:

```bash
qsub -I -A <project_name> -q <queue> -l select=1 -l walltime=60:00 -l singularity_fakeroot=true -l filesystems=home:eagle:grand
```

Next, utilize the [mpich.def](mpich.def) file to construct an image for the container designed to run on CPUs.

```bash
module load singularity
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
singularity build --fakeroot mpich_cpu.sif mpich.def  #cpu only build
```

For GPU execution, construct a custom image based on the base image provided by [nvidia](https://catalog.ngc.nvidia.com/orgs/nvidia/containers/tensorflow) that includes CUDA and NVIDIA drivers. The [tf2-mpich-nvidia-gpu.def](../../datascience/tensorflow/Polaris/tf2-mpich-nvidia-gpu.def) file serves this purpose, utilizing the NVIDIA TensorFlow image as a foundation.

> [!IMPORTANT] 
> Ensure your MPICH is dynamically built by activating the `--disable-wrapper-rpath flag`. Refer to [build_mpich_4.sh](build_mpich_4.sh) for details.


# Scaling on Polaris CPU
To run the container on Polaris, deploy the [job_submission.sh](job_submission.sh) submission script using `qsub -v CONTAINER=mpich_cpu.sif job_submission.sh`. Below is a detailed breakdown of the variable settings for scaling with containers on Polaris.

The subsequent instructions load necessary modules and establish environment variables to guarantee the container runtime's MPICH libraries are bound to the system MPICH.

```bash
module load singularity
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
ADDITIONAL_PATH=/opt/cray/pe/pals/1.1.7/lib/
module load cray-mpich-abi
export SINGULARITYENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:$ADDITIONAL_PATH"
```

Determine the desired number of ranks per node according to your scaling necessities.

```bash
# MPI example w/ 16 MPI ranks per node spread evenly across cores
NODES=`wc -l < $PBS_NODEFILE`
PPN=16
PROCS=$((NODES * PPN))
echo "NUM_OF_NODES= ${NODES} TOTAL_NUM_RANKS= ${PROCS} RANKS_PER_NODE= ${PPN}"
```

To initiate your script:

```bash
echo C++ MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER /usr/source/mpi_hello_world

echo Python MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 /usr/source/mpi_hello_world.py
```

When executed on two nodes, the output should resemble:

```bash
Hello world from processor x3004c0s37b0n0, rank 21 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 20 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 16 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 17 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 24 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 26 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 28 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 29 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 4 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 31 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 18 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 11 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 19 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 5 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 8 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 25 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 10 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 27 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 30 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 14 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 15 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 1 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 3 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 6 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 7 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 0 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 12 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 22 out of 32 processors
Hello world from processor x3004c0s37b0n0, rank 23 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 9 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 13 out of 32 processors
Hello world from processor x3004c0s31b1n0, rank 2 out of 32 processors
```

> [!IMPORTANT] 
> Ensure you pass the necessary system modules by using the bind volume argument `-B` . This is achieved by setting the `-B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric`.


## Scaling on Polaris GPU

To retrieve the custom NVIDIA container from [Argonne GitHub packages](https://github.com/orgs/argonne-lcf/packages):

```bash
singularity pull oras://ghcr.io/argonne-lcf/tf2-mpich-nvidia-gpu:latest
```

Adjust the subsequent environment variables similarly:

```bash
module load singularity
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
CONTAINER=tf2-mpich-nvidia-gpu_latest
ADDITIONAL_PATH=/opt/cray/pe/pals/1.1.7/lib/
module load cray-mpich-abi
export SINGULARITYENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:$ADDITIONAL_PATH"
```

Set the number of ranks per node spread as per your scaling requirements for GPUs

```bash
# 4 GPUS per rank spread evenly across nodes
NNODES=$(wc -l < ${PBS_NODEFILE})
NGPU_PER_NODE=$(nvidia-smi -L | wc -l)
NGPUS=$((${NNODES}*${NGPU_PER_NODE}))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_GPUS= ${NGPUS} GPUS_PER_NODE= ${NGPU_PER_NODE}"
```

It's unnecessary for your code to be integrated into the image. Simply direct to the code you intend to run, and the container will recognize it at runtime. For instance, I transferred a CUDA-aware Python [cuda aware mpi example](source/mpi_cuda_aware_hello_world.py) code into a source directory. I employed -B $PWD to indicate the Python code.

```bash
mpiexec -hostfile $PBS_NODEFILE -n $NGPUS -ppn $NGPU_PER_NODE singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 -B $PWD $CONTAINER python3 $PWD/source/mpi_cuda_aware_hello_world.py
```

If executed on a single node, the output should appear as:

```bash
13:4: not a valid test operator: (
13:4: not a valid test operator: 470.103.04
13:4: not a valid test operator: (
13:4: not a valid test operator: 470.103.04
13:4: not a valid test operator: (
13:4: not a valid test operator: 470.103.04
13:4: not a valid test operator: (
13:4: not a valid test operator: 470.103.04
Hello world from processor x3016c0s7b0n0, rank 1 out of 4 processors
/grand/datascience/atanikanti/container-registry/containers/mpi/Polaris/source/mpi_cuda_aware_hello_world.py:22: DeprecationWarning: `np.int` is a deprecated alias for the builtin `int`. To silence this warning, use `int` by itself. Doing this will not modify any behavior and is safe. When replacing `np.int`, you may wish to use e.g. `np.int64` or `np.int32` to specify the precision. If you wish to review your current use, check the release note link for additional information.
Deprecated in NumPy 1.20; for more details and guidance: https://numpy.org/devdocs/release/1.20.0-notes.html#deprecations
  results = np.empty((size, 10), dtype=np.int)
Hello world from processor x3016c0s7b0n0, rank 3 out of 4 processors
Hello world from processor x3016c0s7b0n0, rank 2 out of 4 processors
Hello world from processor x3016c0s7b0n0, rank 0 out of 4 processors
Results: [[0 0 0 0 0 0 0 0 0 0]
 [1 1 1 1 1 1 1 1 1 1]
 [2 2 2 2 2 2 2 2 2 2]
 [3 3 3 3 3 3 3 3 3 3]]
```
> :Note: Bootstrap by utilizing the [published images] as foundational images to create your personalized containers on Polaris.
> For commonly encountered issues, consult the [troubleshooting](https://docs.alcf.anl.gov/polaris/data-science-workflows/containers/containers/#troubleshooting) section in ALCF documentation.

