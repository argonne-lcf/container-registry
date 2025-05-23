#!/bin/bash

MPICH_VERSION="3.4.3"
MPICH_MAKE_OPTIONS="-j 4" # Assuming 4 cores, adjust if needed

# Exit on error
set -e

echo "--- Downloading MPICH ${MPICH_VERSION} ---"
wget https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz

echo "--- Extracting MPICH ---"
# Create a temporary directory to avoid clutter and use --strip-components
mkdir mpich_src
tar xzf mpich-${MPICH_VERSION}.tar.gz -C mpich_src --strip-components=1
cd mpich_src

echo "--- Configuring MPICH ---"
# Pass options directly to configure, avoid shell variable expansion issues
./configure --prefix=/mpich/install --with-device=ch4:ofi \
	    --disable-wrapper-rpath \
	    --enable-shared \
	    --enable-threads=multiple \
            FFLAGS='-O3 -fallow-argument-mismatch' \
            FCFLAGS='-O3 -fallow-argument-mismatch' \
            CFLAGS='-O3' \
            CXXFLAGS='-O3' # Added CFLAGS/CXXFLAGS here too for consistency

echo "--- Building MPICH ---"
make ${MPICH_MAKE_OPTIONS}

echo "--- Installing MPICH ---"
make install

# Go back and clean up source directory
cd ..
rm -rf mpich_src mpich-${MPICH_VERSION}.tar.gz

echo "--- Updating Environment ---"
export PATH=/mpich/install/bin:$PATH
export LD_LIBRARY_PATH=/mpich/install/lib:$LD_LIBRARY_PATH

echo "--- Verifying mpicc Path ---"
echo "$(which mpicc)"

#echo "--- Installing mpi4py ---"
# Ensure pip uses the correct MPI environment
#MPICC=$(which mpicc) MPICXX=$(which mpicxx) pip install mpi4py

#### BUILD FILES ####
# Ensure the source file exists before trying to compile
if [ -f "/usr/source/mpi_hello_world.c" ]; then
    echo "--- Compiling mpi_hello_world.c ---"
    mpicc -o /usr/source/mpi_hello_world /usr/source/mpi_hello_world.c
    echo "--- Compile Finished ---"
else
    echo "Warning: /usr/source/mpi_hello_world.c not found. Skipping compilation."
fi

echo "--- Script Finished ---"