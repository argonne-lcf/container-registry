# container-registry
To add to this registry follow these steps:

1. Create a personal access token on GitHub by following steps from this [link] (https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token). Ensure you check the repo dropdown checklist

2. Set the environment variable `export CR_PAT=YOUR_TOKEN` in your environment.

3. Replace the NAMESPACE with your personal account username or `argonne-lcf` if you want to publish to the packages repository in Github Argonne

```bash
module load singularity
singularity remote add oras://ghcr.io #do this once
singularity push IMAGE_NAME oras://ghcr.io/NAMESPACE/IMAGE_NAME:latest
```
4. Make your images public by heading to the [packages](https://github.com/orgs/argonne-lcf/packages) page, clicking on your image and adjusting visibility in package settings 

