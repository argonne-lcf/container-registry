# MPI on Sunspot using Apptainer

## Running mpich image on Sunspot

To build an mpich image from scratch, you can follow the instructions given for building an image on [Polaris](../Polaris/READNE,md). To run the image first get the image from a compute node on Sunspot.

```bash
qsub -l select=2 -l walltime=00:30:00 -A Aurora_deployment -q workq -I
module load spack
module load apptainer
module load squashfuse
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
apptainer --fakeroot mpich-4.sif oras://ghcr.io/argonne-lcf/mpich-4:latest
```

To run the image using a job submission script

```bash
qsub job_submission.sh
```


