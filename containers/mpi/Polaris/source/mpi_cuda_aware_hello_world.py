from mpi4py import MPI
import numpy as np
import cupy as cp

def compute_on_gpu(data):
    # Replace this with actual GPU computation using CuPy or any other library.
    gpu_data = cp.array(data)
    return cp.asnumpy(gpu_data)

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    name = MPI.Get_processor_name()
    #print(f"Hello, World from Rank {rank}")  # adding Hello World print statement with rank
    print(f"Hello world from processor {name}, rank {rank} out of {size} processors")

    data = np.array([rank] * 10)
    gpu_result = compute_on_gpu(data)

    if rank == 0:
        results = np.empty((size, 10), dtype=np.int)
    else:
        results = None

    comm.Gather(gpu_result, results, root=0)

    if rank == 0:
        print('Results:', results)

if __name__ == '__main__':
    main()
