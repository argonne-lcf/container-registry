#!/bin/bash -l
# This script is designed for local execution (e.g., ./run_local_container.sh)
# It uses the hybrid model with an internal MPI build, attempting
# to link dynamically to host PMI/PALS via SINGULARITYENV_LD_LIBRARY_PATH.
# It does NOT use PBS/qsub.

# Ensure script is run from the correct directory (e.g., .../source)
EXPECTED_DIR_NAME="source"
CURRENT_DIR_NAME=${PWD##*/}
if [ "$CURRENT_DIR_NAME" != "$EXPECTED_DIR_NAME" ]; then
    echo "Error: Please run this script from the 'source' directory." 
    exit 1
fi


# Define container
#CONTAINER=${PWD}/../mpich_4.2.3.sif # Path relative to the 'source' directory
if [ ! -f "${CONTAINER}" ]; then
    echo "Error: Container file not found at ${CONTAINER}"
    exit 1
fi

# --- Build the code inside the container --- 
# (Assumes the binary links against /opt/mpich-4.2.3/lib/libmpi.so inside)
echo "Building hello_affinity inside the container..."
# Mount PWD (source dir) to /app inside, and run make there
apptainer exec --fakeroot -B ${PWD}:/app ${CONTAINER} make -C /app clean hello_affinity
if [ $? -ne 0 ]; then
    echo "Container build failed!"
    exit 1
fi
echo "Build complete."
# -------------------------------------------


# MPI example for local execution (adjust as needed)
NNODES=1 # Running locally on one node
NRANKS_PER_NODE=2 # Run 2 ranks locally for testing
NDEPTH=4 # Assign 4 cores per rank (adjust based on node's core count)
NTHREADS=1 

NTOTRANKS=$(( NNODES * NRANKS_PER_NODE ))
echo "LOCAL HYBRID RUN (using APPTAINERENV_LD_LIBRARY_PATH): TOTAL_NUM_RANKS= ${NTOTRANKS} RANKS_PER_NODE= ${NRANKS_PER_NODE} THREADS_PER_RANK= ${NTHREADS} DEPTH= ${NDEPTH}"

# IMPORTANT: Set SINGULARITYENV_LD_LIBRARY_PATH
# This sets LD_LIBRARY_PATH INSIDE the container to prioritize host libs for PMI/PALS/Fabric.
# The application (/app/hello_affinity) should still find its own linked libmpi.so 
# from /opt/mpich-4.2.3/lib because that path is in the container's default environment.
HOST_LIBS_FOR_CONTAINER=/opt/cray/pe/mpich/8.1.28/ofi/nvidia/23.3/lib:/opt/cray/libfabric/1.15.2.0/lib64:/opt/cray/pe/pmi/6.1.13/lib:/opt/cray/pals/1.3.4/lib:/opt/nvidia/hpc_sdk/Linux_x86_64/23.9/compilers/lib:/usr/lib64
export APPTAINERENV_LD_LIBRARY_PATH="${HOST_LIBS_FOR_CONTAINER}"

# The host mpiexec should find its libs via the standard module environment

echo "Affinitying using cpu-bind depth (Local Container Hybrid with SINGULARITYENV)"
mpiexec -n ${NTOTRANKS} --depth=${NDEPTH} --cpu-bind depth \
    apptainer exec --fakeroot \
    -B $PWD:/app \
    -B /opt/cray:/opt/cray \
    -B /opt/nvidia:/opt/nvidia \
    -B /var/run/palsd:/var/run/palsd \
    ${CONTAINER} /app/hello_affinity 
    # No longer passing --env LD_LIBRARY_PATH, relies on SINGULARITYENV_LD_LIBRARY_PATH

# Clean up env var if desired
#unset SINGULARITYENV_LD_LIBRARY_PATH

# Optional: Add the list binding test back if needed
# export SINGULARITYENV_LD_LIBRARY_PATH="${HOST_LIBS_FOR_CONTAINER}"
# echo "Affinitying using cpu-bind list (Local Container Hybrid with SINGULARITYENV)"
# CPU_BIND_LIST="list:0-3:4-7" # Example for NRANKS=2, NDEPTH=4
# mpiexec -n ${NTOTRANKS} --cpu-bind ${CPU_BIND_LIST} \
#     apptainer exec --fakeroot \
#     -B $PWD:/app \
#     -B /opt/cray:/opt/cray \
#     -B /opt/nvidia:/opt/nvidia \
#     -B /var/run/palsd:/var/run/palsd \
#     ${CONTAINER} /app/hello_affinity
# unset SINGULARITYENV_LD_LIBRARY_PATH 