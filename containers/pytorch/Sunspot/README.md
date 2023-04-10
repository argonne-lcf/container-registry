# MPI on Sunspot using Apptainer

## Running mpich image on Sunspot

To scale pytorch on Sunspot you can use the [intel-optimized-pytorch.def](intel-optimized-pytorch.def) file which is built from [intel optimized pytorch image](https://hub.docker.com/r/intel/intel-optimized-pytorch) and build mpich in it. To run the compute node on Sunspot.

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
apptainer build --fakeroot intel-optimized-pytorch.sif intel-optimized-pytorch.def
```

To run the image using a job submission script

```bash
qsub -v CONTAINER=intel-optimized-pytorch.sif job_submission.sh
```


