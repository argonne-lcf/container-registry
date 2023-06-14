# CONTAINER REGISTRY

## TABLE OF CONTENTS

1. [Databases](containers/databases): Container scripts to launch mongo, mysql, neo4j or postgres
2. [mpich](containers/mpi): Container scripts to run mpich codes
3. [datascience](containers/datascience): Container scripts to run tensorflow, pytorch, horovod
4. [shpc](containers/shpc): Singularity Registry HPC (shpc) allows you to install containers as modules

## CONTRIBUTIONS
To contribute to this registry follow these steps (Only for ALCF Github members):

1. Create a personal access token on GitHub by following steps from this [link] (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). Ensure you check the repo dropdown checklist

2. Set the environment variable `export CR_PAT=YOUR_TOKEN` in your environment.

3. Replace the NAMESPACE with your personal account username or `argonne-lcf` if you want to publish to the packages repository in Github Argonne

```bash
module load singularity
singularity remote add oras oras://ghcr.io #do this once and skip token
singularity remote login --username <username> oras://ghcr.io/ #do this once and paste the token created from step 1.
singularity push IMAGE_NAME oras://ghcr.io/NAMESPACE/IMAGE_NAME:latest
```
4. Make your images public by heading to the [packages](https://github.com/orgs/argonne-lcf/packages) page, clicking on your image and adjusting visibility in package settings

5. To pull from this repository

```bash
singularity pull oras://ghcr.io/argonne-lcf/IMAGE_NAME:latest
```

