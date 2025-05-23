#!/bin/bash -l
#PBS -l select=1:system=polaris
#PBS -l place=scatter
#PBS -l walltime=0:30:00
#PBS -q debug 
#PBS -A Catalyst # <<< CHANGE THIS TO YOUR PROJECT ALLOCATION
#PBS -l filesystems=home:grand:eagle

cd ${PBS_O_WORKDIR}

# Define container
#CONTAINER=${PWD}/../mpich_4.2.3.sif # Adjust path if needed

# --- Build the code inside the container ---
echo "Building hello_affinity inside the container..."
# Mount PWD (source dir) to /app inside, and run make there
apptainer exec --fakeroot -B ${PWD}:/app ${CONTAINER} make -C /app clean hello_affinity
if [ $? -ne 0 ]; then
    echo "Container build failed!"
    exit 1
fi
echo "Build complete."
# -------------------------------------------


# MPI example w/ 4 MPI ranks per node w/ threads spread evenly across cores (1 thread per core)
NNODES=`wc -l < $PBS_NODEFILE`
NRANKS_PER_NODE=4
NDEPTH=8 # This will assign 8 cores per rank (Polaris nodes have 64 cores/node -> 64/4 = 16, NDEPTH=16 might be more suitable for 4 ranks/node? Let's try 8 first)
NTHREADS=1 # Corresponds to the C++ code (no OpenMP)

NTOTRANKS=$(( NNODES * NRANKS_PER_NODE ))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_RANKS= ${NTOTRANKS} RANKS_PER_NODE= ${NRANKS_PER_NODE} THREADS_PER_RANK= ${NTHREADS} DEPTH= ${NDEPTH}"

# IMPORTANT: Set the LD_LIBRARY_PATH for the HOST mpiexec to find Cray libs
# This is based on the paths seen in the successful README examples.
HOST_LD_LIBRARY_PATH=/opt/cray/pe/mpich/8.1.28/ofi/nvidia/23.3/lib:/opt/cray/libfabric/1.15.2.0/lib64:/opt/cray/pe/pmi/6.1.13/lib:/opt/cray/pals/1.3.4/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib:/usr/lib64

echo "Affinitying using cpu-bind depth (Container Hybrid)"
mpiexec -n ${NTOTRANKS} --ppn ${NRANKS_PER_NODE} --depth=${NDEPTH} --cpu-bind depth \
    apptainer exec --fakeroot \
    -B $PWD:/app \
    -B /opt/cray \
    -B /opt/nvidia/hpc_sdk \
    -B /usr/lib64:/host_lib64 \
    -B /var/run/palsd \
    --env LD_LIBRARY_PATH="${HOST_LD_LIBRARY_PATH}" \
    ${CONTAINER} /app/hello_affinity

echo "Affinitying using cpu-bind list (Container Hybrid)"
# Example core list for NRANKS_PER_NODE=4, NDEPTH=8 on a 64-core node
# R0: 0-7, R1: 8-15, R2: 16-23, R3: 24-31
CPU_BIND_LIST="list:0-7:8-15:16-23:24-31"
mpiexec -n ${NTOTRANKS} --ppn ${NRANKS_PER_NODE} --cpu-bind ${CPU_BIND_LIST} \
    apptainer exec --fakeroot \
    -B $PWD:/app \
    -B /opt/cray \
    -B /opt/nvidia/hpc_sdk \
    -B /usr/lib64:/host_lib64 \
    -B /var/run/palsd \
    --env LD_LIBRARY_PATH="${HOST_LD_LIBRARY_PATH}" \
    ${CONTAINER} /app/hello_affinity 