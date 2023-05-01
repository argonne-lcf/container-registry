# MPI on Sunspot using Apptainer

## Running mpich image on Sunspot

To build an mpich image from scratch, you can follow the instructions given for building an image on [Polaris](../Polaris/README.md). Alternatively you can just pull the prebuilt image from the registry as shown below on a Sunspot worker node.

```bash
qsub -l select=2 -l walltime=00:30:00 -A Aurora_deployment -q workq -I
module load spack
module load apptainer
module load squashfuse
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
apptainer build --fakeroot mpich-4.sif oras://ghcr.io/argonne-lcf/mpich-4:latest
```

To run an mpich image on Sunspot, clone this repository as you will need [mpich_libraries](mpich_libraries) to run the image. You can use the [job_submission.sh](job_submission.sh) script to run the image.

```bash
qsub -v CONTAINER=mpich-4.sif job_submission.sh
```


