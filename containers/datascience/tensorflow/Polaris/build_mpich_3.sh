#!/bin/bash

MPICH_VERSION="3.3.2"
MPICH_CONFIGURE_OPTIONS="--prefix=/mpich/install --disable-wrapper-rpath FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch"
#MPICH_CONFIGURE_OPTIONS="--prefix=/mpich/install --disable-wrapper-rpath"
MPICH_MAKE_OPTIONS="-j 4"

wget https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz \
	&& tar xzf mpich-${MPICH_VERSION}.tar.gz  --strip-components=1 \
	&& ./configure ${MPICH_CONFIGURE_OPTIONS} \
	&& make install ${MPICH_MAKE_OPTIONS}

export PATH=$PATH:/mpich/install/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mpich/install/lib
export HOROVOD_WITH_MPI=1
pip uninstall -y horovod[all-frameworks]
MPICC=$(which mpicc) MPICXX=$(which mpicxx) pip install mpi4py
MPICC=$(which mpicc) MPICXX=$(which mpicxx) pip install mpi4jax
MPICC=$(which mpicc) MPICXX=$(which mpicxx) pip install horovod[all-frameworks]
pip install -r /usr/requirements.txt
#pip install mpi4py
#pip install mpi4jax
#### BUILD FILES ####
mpicc -o /usr/source/mpi_hello_world /usr/source/mpi_hello_world.c
