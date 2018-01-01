# Jupyterhub on Kubernetes with Terraform

The goal is to create a Jupyterhub instance on Kubernetes 

## ARC-TS / Advanced Research Computing - Technology Services 

hpc-support@umich.edu


 * TODO: Document IAM Roles
 * TODO: Setup OAUTH
 * TODO: Setup Oauth against Globus
 * TODO: Add containers for addons eg. Julia
 * TODO: Document how to add starting data to notebooks
 * TODO: Document how to change instance type
 * TODO: Document how to change resource claim per notebook
 * TODO: Remove extra centos pod 

## Setup

 1. Generate SSL Keys and Cert (This takes time from the authority)
  1. `openssl req -new -newkey rsa:2048 -keyout DNS.gcp.arc-ts.umich.edu.key -out dns.gcp.arc-ts.umich.edu.csr`
  1. Remove password from key: `openssl rsa -in DNS.gcp.arc-ts.umich.edu.key -out no-pass.key`
  1. Use the password free key in your `tfvars` config file
 1. Setup Cloud DNS Zone if not already exists in your project
 1. Setup OAuth provider at Globus.org ["https://github.com/jupyterhub/oauthenticator"]
 1. Copy `example.tfvars` and edit for your own values
 1. Validate plan: `terraform plan -var-file=custom.tfvars`
 1. Apply plan: `terraform apply -var-file=custom.tfvars`
 1. Tear it all down: `terraform destory -var-file=custom.tfvars`

## Optional 

 * Edit `config.tf`  to change what jupyterhub container starts on each login
 * Force recreation of `jupyterhub` pod, commonly needed if config is changed `terraform taint -module=jupyterhub kubernetes_pod.jupyterhub`
 * Connect to container with a shell: 
```
gcloud container clusters get-credentials marcellus-wallace --zone us-central1-a --project brockp-terraform-admin \&& kubectl exec jupyter-notebook -c hub -i -t -- /bin/bash
```

## Globus.org OAuth

 * Instructions: ["https://github.com/jupyterhub/oauthenticator#globus-setup"]
 * Scopes: `openid profile urn:globus:auth:scope:transfer.api.globus.org:all`
 * Redirects: `https://dns.gcp.arc-ts.umich.edu/hub/oauth_callback`
 * Select: Require a specific Identity Provider: University of Michigan
 * Select: Pre-select Identity Provider: University of Michigan
 * Leave rest as defaults
 * Generate Secret: STORE SECURELY
 * Set options in `<config>.tfvars`

## Docker Container for Hub

 * The `images` folder has a container deffinition for a jupyterhub with the needed addons
 * Update to latest jupyterhub base container: `docker pull jupyterhub/jupyterhub`
 * Build eg: `docker build -t brockp/juputerhub-k8s:0.3 .`
 * Push to dockerhub: `docker push brockp/jupyterhub-k8s:0.3`
 * Update `juptyerhub/main.tf` to point to the new version/container
