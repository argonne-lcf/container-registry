"""
Prints MPI rank, hostname, and CPU affinity using mpi4py.
"""

from mpi4py import MPI
import os
import socket

def format_core_list(core_set):
    """ Formats a set of integer cores into a string like (0-3) or (0, 2, 4-6). """
    if not core_set:
        return "(none)"

    cores = sorted(list(core_set))

    if not cores:
        return "(none)"

    result = []
    i = 0
    while i < len(cores):
        start_range = cores[i]
        j = i + 1
        while j < len(cores) and cores[j] == cores[j-1] + 1:
            j += 1
        end_range = cores[j-1]

        if start_range == end_range:
            result.append(str(start_range))
        else:
            result.append(f"{start_range}-{end_range}")
        i = j

    return f"({', '.join(result)})"

def main():
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    hostname = socket.gethostname()

    try:
        # Get affinity for the current process (PID 0)
        affinity_set = os.sched_getaffinity(0)
        core_list_str = format_core_list(affinity_set)
    except AttributeError:
        core_list_str = "(affinity not available)" # os.sched_getaffinity might not be available everywhere
    except OSError as e:
        core_list_str = f"(error getting affinity: {e})"


    print(f"To affinity and beyond!! nname= {hostname}  rnk= {rank}  list_cores= {core_list_str}")

if __name__ == "__main__":
    main() 