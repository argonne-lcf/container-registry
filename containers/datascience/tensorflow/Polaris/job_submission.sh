#!/bin/sh
#PBS -l select=2:system=polaris
#PBS -q debug-scaling
#PBS -l place=scatter
#PBS -l walltime=0:30:00
#PBS -l filesystems=home:grand
#PBS -A datascience

cd ${PBS_O_WORKDIR}
echo $CONTAINER

# SET proxy for internet access
module load singularity
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128

# Needed for Polaris PE to map to Singularity
ADDITIONAL_PATH=/opt/cray/pe/pals/1.1.7/lib/
module load cray-mpich-abi
export SINGULARITYENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:$ADDITIONAL_PATH"


# 4 GPUS per ranks spread evenly across cores
NNODES=$(wc -l < ${PBS_NODEFILE})
NGPU_PER_NODE=$(nvidia-smi -L | wc -l)
NGPUS=$((${NNODES}*${NGPU_PER_NODE}))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_GPUS= ${NGPUS} GPUS_PER_NODE= ${NGPU_PER_NODE}"


# Openmpi Does not work on Polaris
# Test MPICH 
# echo C++ MPI
# mpiexec -hostfile $PBS_NODEFILE -n $NGPUS -ppn $NGPU_PER_NODE singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER /usr/source/mpi_hello_world

#echo Python MPI
# mpiexec -hostfile $PBS_NODEFILE -n $NGPUS -ppn $NGPU_PER_NODE singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 /usr/source/mpi_hello_world.py

# Run Cosmic Tagger
#git clone https://github.com/coreyjadams/CosmicTagger.git

# GPU Only with tensorflow
mpiexec -hostfile $PBS_NODEFILE -n $NGPUS -ppn $NGPU_PER_NODE singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 CosmicTagger/bin/exec.py --config-name a21 framework=tensorflow run.id=test-1 run.compute_mode=GPU run.distributed=True run.precision="float32" run.minibatch_size=2 run.iterations=20


# CPU example with 16 ranks per node
# PPN=16
# PROCS=$((NNODES * PPN))
# echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_RANKS= ${PROCS} RANKS_PER_NODE= ${PPN}"

# CPU Only with tensorflow
# mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 CosmicTagger/bin/exec.py --config-name a21 framework=tensorflow run.id=test-1 run.compute_mode=CPU run.distributed=True run.precision="float32" run.minibatch_size=2 run.iterations=20

