#!/bin/bash -l
# This script is designed for local execution (e.g., ./run_local_hybrid.sh)
# It uses the hybrid model with the container containing pre-built code.
# Uses SINGULARITYENV_LD_LIBRARY_PATH for host PMI/PALS integration.
# It does NOT use PBS/qsub.

# Ensure script is run from the correct directory (e.g., .../source)
EXPECTED_DIR_NAME="source"
CURRENT_DIR_NAME=${PWD##*/}
if [ "$CURRENT_DIR_NAME" != "$EXPECTED_DIR_NAME" ]; then
    echo "Error: Please run this script from the 'source' directory." 
    exit 1
fi

# Define container (Using the container with MPICH 3.4a2 + pre-built code)
CONTAINER=${PWD}/../mpich_3.4a2_with_code.sif # Path relative to the 'source' directory
if [ ! -f "${CONTAINER}" ]; then
    echo "Error: Container file not found at ${CONTAINER}"
    exit 1
fi

# --- Build step is removed - code is pre-compiled in container ---

# MPI example for local execution (adjust as needed)
NNODES=1 
NRANKS_PER_NODE=2 
NDEPTH=4 
NTHREADS=1 

NTOTRANKS=$(( NNODES * NRANKS_PER_NODE ))
echo "LOCAL HYBRID RUN (PRE-BUILT CODE): TOTAL_NUM_RANKS= ${NTOTRANKS} RANKS_PER_NODE= ${NRANKS_PER_NODE} THREADS_PER_RANK= ${NTHREADS} DEPTH= ${NDEPTH}"

# IMPORTANT: Set SINGULARITYENV_LD_LIBRARY_PATH for host libs
HOST_LIBS_FOR_CONTAINER=/opt/cray/pe/mpich/8.1.28/ofi/nvidia/23.3/lib:/opt/cray/libfabric/1.15.2.0/lib64:/opt/cray/pe/pmi/6.1.13/lib:/opt/cray/pals/1.3.4/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib:/usr/lib64
export SINGULARITYENV_LD_LIBRARY_PATH="${HOST_LIBS_FOR_CONTAINER}"

# --- Run C++ Example ---
echo "Running C++ Affinity Check (Hybrid with SINGULARITYENV)"
mpiexec -n ${NTOTRANKS} --depth=${NDEPTH} --cpu-bind depth \
    apptainer exec --fakeroot \
    -B /opt/cray:/opt/cray \
    -B /opt/nvidia:/opt/nvidia \
    -B /var/run/palsd:/var/run/palsd \
    ${CONTAINER} ldd /usr/bin/hello_affinity  # Check LDD on the correct path inside container

# --- Run Python Example ---
#echo "Running Python Affinity Check (Hybrid with SINGULARITYENV)"


# Clean up env var
unset SINGULARITYENV_LD_LIBRARY_PATH 