#!/bin/sh
#PBS -l select=2:system=sunspot
#PBS -q workq
#PBS -l place=scatter
#PBS -l walltime=0:30:00
#PBS -A Aurora_deployment

cd ${PBS_O_WORKDIR}
echo $CONTAINER

# Load necessart modules and set proxy for internet access
module load spack
module load apptainer
module load squashfuse
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128

# Needed for Sunspot to map to Apptainer
ADDITIONAL_PATH=$PWD/mpich_libraries

# MPI example w/ 16 MPI ranks per node spread evenly across cores
NODES=`wc -l < $PBS_NODEFILE`
PPN=16
PROCS=$((NODES * PPN))
echo "NUM_OF_NODES= ${NODES} TOTAL_NUM_RANKS= ${PROCS} RANKS_PER_NODE= ${PPN}"

export APPTAINERENV_LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$ADDITIONAL_PATH"

echo C++ MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN apptainer exec -B /opt -B /soft -B $PWD $CONTAINER /usr/source/mpi_hello_world

echo Python MPI
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN apptainer exec -B /opt -B /soft -B $PWD $CONTAINER python3 /usr/source/mpi_hello_world.py
