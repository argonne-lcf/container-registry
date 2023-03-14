# MPICH ON Polaris

# Building a mpich image on Polaris
To build a mpich image on Polaris, you will have to first land on a compute node in interactive mode and then you can use the mpich.def file found in this repo.

```bash
qsub -I -A <project_name> -q <queue> -l select=1 -l walltime=60:00 -l singularity_fakeroot=true -l filesystems=home:eagle:grand
module load singularity
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
singularity build --fakeroot <image_name>.sif <def_filename>.def 
```
Ensure your mpich is dynamically built. This is achieved by setting the '--disable-wrapper-rpath' flag. You can refer to the `build_mpich.sh` file found in this repo.

# Running the mpich image

To run a container on Polaris you can either use the submission script described in this repo. Or in the compute node set the following variables in order for container mpich to bind to system mpich


```bash
ADDITIONAL_PATH=/opt/cray/pe/pals/1.1.7/lib/
module load cray-mpich-abi
export SINGULARITYENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:$ADDITIONAL_PATH"
```

Set the number of ranks per node spread as per your scaling requirements

```bash
# MPI example w/ 16 MPI ranks per node spread evenly across cores
NODES=`wc -l < $PBS_NODEFILE`
PPN=16
PROCS=$((NODES * PPN))
echo "NUM_OF_NODES= ${NODES} TOTAL_NUM_RANKS= ${PROCS} RANKS_PER_NODE= ${PPN}"
```

Finally launch your script

```bash
echo C++ MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt -B /var/run/palsd/ $CONTAINER /usr/source/mpi_hello_world

echo Python MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt -B /var/run/palsd/ $CONTAINER python3 /usr/source/mpi_hello_world.py
```
