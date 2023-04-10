#!/bin/bash

MPICH_VERSION="4.0.2"
MPICH_CONFIGURE_OPTIONS="--prefix=/mpich/install --disable-wrapper-rpath"
MPICH_MAKE_OPTIONS="-j 4"
wget https://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz \
	&& tar xzf mpich-${MPICH_VERSION}.tar.gz  --strip-components=1 \
	&& ./configure ${MPICH_CONFIGURE_OPTIONS} \
	&& make install ${MPICH_MAKE_OPTIONS}

export PATH=$PATH:/mpich/install/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mpich/install/lib

pip install mpi4py

#### BUILD FILES ####
mpicc -o /usr/source/mpi_hello_world /usr/source/mpi_hello_world.c

