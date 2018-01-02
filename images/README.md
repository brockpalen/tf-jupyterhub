# Jupyterhub with Kubernetes

This is part of a full Google Cloud (And maybe others) Terraform confiruration.
It will likely not run on its own.  The CMD/ENTRYPOINT is not commonly used

See: [https://github.com/brockpalen/tf-jupyterhub] 

## Docker Container for Hub

 * The `images` folder has a container deffinition for a jupyterhub with the needed addons
 * Update to latest jupyterhub base container: `docker pull jupyterhub/jupyterhub`
 * Build eg: `docker build -t brockp/juputerhub-k8s:0.3 .`
 * Push to dockerhub: `docker push brockp/jupyterhub-k8s:0.3`
 * Update `juptyerhub/main.tf` to point to the new version/container
