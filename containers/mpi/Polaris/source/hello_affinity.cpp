#include <mpi.h>
#include <stdio.h>
#include <unistd.h> // For gethostname
#include <limits.h> // For HOST_NAME_MAX
#include <sched.h>  // For sched_getaffinity
#include <string>
#include <sstream>
#include <vector>
#include <algorithm> // for std::sort

// Function to format the core list like (0-3) or (0, 2, 4-6)
std::string format_core_list(const cpu_set_t& mask, int num_cpus) {
    std::vector<int> cores;
    for (int i = 0; i < num_cpus; ++i) {
        if (CPU_ISSET(i, &mask)) {
            cores.push_back(i);
        }
    }
    if (cores.empty()) {
        return "(none)";
    }

    std::sort(cores.begin(), cores.end());

    std::stringstream ss;
    ss << "(";
    size_t i = 0;
    while (i < cores.size()) {
        int start_range = cores[i];
        size_t j = i + 1;
        while (j < cores.size() && cores[j] == cores[j - 1] + 1) {
            j++;
        }
        int end_range = cores[j - 1];

        if (i > 0) {
            ss << ", ";
        }

        ss << start_range;
        if (end_range > start_range) {
            ss << "-" << end_range;
        }
        i = j;
    }
    ss << ")";
    return ss.str();
}


int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);

    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    char hostname[HOST_NAME_MAX];
    gethostname(hostname, HOST_NAME_MAX);

    cpu_set_t mask;
    CPU_ZERO(&mask);
    if (sched_getaffinity(0, sizeof(cpu_set_t), &mask) == -1) {
        perror("sched_getaffinity");
    }

    // Determine the total number of CPUs available to query the mask correctly
    long num_cpus = sysconf(_SC_NPROCESSORS_ONLN);
    if (num_cpus < 1) {
        num_cpus = 1024; // Fallback reasonable upper limit
    }

    std::string core_list_str = format_core_list(mask, num_cpus);

    printf("To affinity and beyond!! nname= %s  rnk= %d  list_cores= %s\\n",
           hostname, world_rank, core_list_str.c_str());

    MPI_Finalize();
    return 0;
} 