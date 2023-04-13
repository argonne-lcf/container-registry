# MPI on Sunspot using Apptainer

## Running mpich image on Sunspot

To scale pytorch on Sunspot you can either use the [intel-optimized-pytorch-with-mpich.def](intel-optimized-pytorch-with-mpich.def) def file which is built from [intel optimized pytorch image](https://hub.docker.com/r/intel/intel-optimized-pytorch) and custom [mpich-4](build_mpich.sh) or just use `apptainer pull oras://ghcr.io/argonne-lcf/intel-optimized-pytorch-with-mpich:latest`.

```bash
qsub -l select=2 -l walltime=00:30:00 -A Aurora_deployment -q workq -I
git clone git@github.com:argonne-lcf/container-registry.git
cd container-registry/containers/pytorch/Sunspot
module load spack
module load apptainer
module load squashfuse
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
apptainer build --fakeroot intel-optimized-pytorch-with-mpich.sif intel-optimized-pytorch-with-mpich.def
#or apptainer pull oras://ghcr.io/argonne-lcf/intel-optimized-pytorch-with-mpich:latest
```

To run the image, you will need the [mpich_libraries](mpich_libraries) folder found in this repository. You can use the [job submission script](job_submission.sh) as a working example.

```bash
qsub -v CONTAINER=intel-optimized-pytorch-with-mpich_latest.sif job_submission.sh
```
 


