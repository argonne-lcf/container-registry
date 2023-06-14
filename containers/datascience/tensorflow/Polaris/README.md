# Tensorflow on Polaris using Singularity

# Run with prebuilt tensorflow image 

1. Pull container from Argonne GitHub container registry

```bash
module load singularity
singularity pull oras://ghcr.io/argonne-lcf/tf2-py3-nvidia-gpu:latest
```

2. To run a container on Polaris you can either use the [submission script](job_submission.sh) described in this repo. Alternatively, in interactive mode on the compute node set the following variables in order for container mpich to bind to system mpich

```bash
qsub -l select=2 -l walltime=00:30:00 -A <project> -q debug -l singularity_fakeroot=true -l filesystems=home:grand -I
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
ADDITIONAL_PATH=/opt/cray/pe/pals/1.1.7/lib/
module load cray-mpich-abi
export SINGULARITYENV_LD_LIBRARY_PATH="$CRAY_LD_LIBRARY_PATH:$LD_LIBRARY_PATH:$ADDITIONAL_PATH"
```

3. Set the number of nodes / gpus you would like to run your code

```bash
# 4 GPUS per rank spread evenly across nodes
NNODES=$(wc -l < ${PBS_NODEFILE})
NGPU_PER_NODE=$(nvidia-smi -L | wc -l)
NGPUS=$((${NNODES}*${NGPU_PER_NODE}))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_GPUS= ${NGPUS} GPUS_PER_NODE= ${NGPU_PER_NODE}"
```

4. To run cosmic tagger clone the [repository](https://github.com/coreyjadams/CosmicTagger), bind the necessary system modules and run the following script. Here $CONTAINER is tf2-mpich-nvidia-gpu_latest.sif

```bash
# Run Cosmic Tagger
git clone https://github.com/coreyjadams/CosmicTagger.git

# GPU Only with tensorflow
mpiexec -hostfile $PBS_NODEFILE -n $NGPUS -ppn $NGPU_PER_NODE singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 CosmicTagger/bin/exec.py --config-name a21 framework=tensorflow run.id=test-1 run.compute_mode=GPU run.distributed=True run.precision="float32" run.minibatch_size=2 run.iterations=20

# CPU example with 16 ranks per node
PPN=16
PROCS=$((NNODES * PPN))
echo "NUM_OF_NODES= ${NNODES} TOTAL_NUM_RANKS= ${PROCS} RANKS_PER_NODE= ${PPN}"

# CPU Only with tensorflow
mpiexec -hostfile $PBS_NODEFILE -n $PROCS -ppn $PPN singularity exec -B /opt/nvidia -B /var/run/palsd/ -B /opt/cray/pe -B /opt/cray/libfabric $CONTAINER python3 CosmicTagger/bin/exec.py --config-name a21 framework=tensorflow run.id=test-1 run.compute_mode=CPU run.distributed=True run.precision="float32" run.minibatch_size=2 run.iterations=20
```

5. To build a container from scratch you can use the [tf2-mpich-nvidia-gpu.def](tf2-mpich-nvidia-gpu.def) file followed by singularity build --fakeroot on a compute node

```bash
qsub -l select=1 -l walltime=00:30:00 -A <project> -q debug -l singularity_fakeroot=true -l filesystems=home:grand -I
git clone git@github.com:argonne-lcf/container-registry.git
cd container-registry/containers/datascience/tensorflow
export HTTP_PROXY=http://proxy.alcf.anl.gov:3128
export HTTPS_PROXY=http://proxy.alcf.anl.gov:3128
export http_proxy=http://proxy.alcf.anl.gov:3128
export https_proxy=http://proxy.alcf.anl.gov:3128
singularity build --fakeroot tf2-mpich-nvidia-gpu.sif tf2-mpich-nvidia-gpu.def
```
