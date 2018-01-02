###############################################################################
##
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
# DO NOT NORMALLY EDIT THESE FILES
#    see: https://www.terraform.io/docs/configuration/variables.html Variable Files
#
#  See example.tfvars
#
#  Put all options in .tfvars eg:
#    terraform plan -var-file=rajrao.tfvars

###############################################################################
## Google Region 

variable "gcp_region" {
  description = "The region to place the cluster"
  default     = "us-central1"
}

###############################################################################
## Google Project 

variable "gcp_project" {
  description = "Google Project to invoke under"
  default     = "brockp-terraform-admin"
}

###############################################################################
## DNS Setup 
variable "enable_dns" {
   default = false
}

variable "dns_zone" {
  description = "manged DNS zone, as named in cloud provider"
  default     = "gcp-arcts-zone"
}

variable "dns_name" {
  description = "FQDN including trailing . (for google) to use for service"
  default     = "rajrao.gcp.arc-ts.umich.edu."
}

###############################################################################
## SSL Configuration
variable "ssl_cert" {
  type        = "map"
  description = "ssl certificate keys used by proxy"
}

###############################################################################
## Globus OAUTH Configuration
variable "globus_oauth" {
  type        = "map"
  description = "Globus OAuth callback, client_id, and secret"
}

###############################################################################
## 
#  google container engine configs
variable "gke_options" {
   type = "map"
   description = "global options for gke/kubernetes"
   default = {
      name = "arcts-kube"
      initial_node_count = 3
      #zone = ""   # if not defined takes first from data "google_compute_zones" "available" {}
      preemptible = false
      disk_size_gb = 10   # size in GB, 10 is minimum value
      machine_type = "n1-standard-1"
   }
}

###############################################################################
##
#  Configuration file for jupyterhub
#  Spawner options: http://jupyterhub-kubespawner.readthedocs.io/en/latest/spawner.html
#  Jupyterhub Opitions: https://github.com/jupyterhub/kubespawner/blob/master/jupyterhub_config.py

resource "kubernetes_config_map" "jupyterhub-config" {
  metadata {
    name = "jupyterhub-config"
  }

  data {
    jupyterhub-config.py = <<EOM

##  User Kubernetes Spawner
#   each time a user logs in a new POD is spawned,
c.JupyterHub.spawner_class='kubespawner.KubeSpawner'
c.KubeSpawner.start_timeout=1000

# Which container to spawn
c.KubeSpawner.singleuser_image_spec='jupyterhub/singleuser:0.8'
c.KubeSpawner.singleuser_service_account='default'
c.KubeSpawner.user_storage_pvc_ensure=True
c.KubeSpawner.debug=True

## mount in the NFS server to keep notebooks and data around between sessions
#c.KubeSpawner.volumes=[
#  {
#    'name': 'nfs-volume', 
#    'persistentVolumeClaim': {
#      'claimName': '${module.kube-nfs.nfs-volume}'
#    }
#  }
# ]
#c.KubeSpawner.volume_mounts=[
#  {
#    'name':'nfs-volume',
#    'mountPath':'/mnt/'
#  }
# ]

## Authentication section
# Options:
#  - dummyauthenticator.DummyAuthenticator
#  - ldap
#  - k5
#  - oauth

## Uncomment to have no auth
# c.JupyterHub.authenticator_class='dummyauthenticator.DummyAuthenticator'

## Place other auth options here

## Globus OAuth https://github.com/jupyterhub/oauthenticator#globus-setup
from oauthenticator.globus import LocalGlobusOAuthenticator
c.JupyterHub.authenticator_class = LocalGlobusOAuthenticator
#c.LocalGlobusOAuthenticator.enable_auth_state = True
c.LocalGlobusOAuthenticator.oauth_callback_url = "${var.globus_oauth["callback_url"]}"
c.LocalGlobusOAuthenticator.client_id = "${var.globus_oauth["client_id"]}"
c.LocalGlobusOAuthenticator.client_secret = "${var.globus_oauth["client_secret"]}"
c.GlobusOAuthenticator.identity_provider = "${var.globus_oauth["identity_provider"]}"

# standard options Don't change
c.JupyterHub.allow_named_servers=True
c.JupyterHub.ip='0.0.0.0'
c.JupyterHub.hub_ip='0.0.0.0'
c.JupyterHub.cleanup_servers=False

# Don't start the Proxy 
c.ConfigurableHTTPProxy.should_start=False
c.JupyterHub.logo_file='/srv/jupyterhub/images/arcts-acronym-informal-sm.png'

EOM
  }
}

###############################################################################
## 
#   END JUPYTERHUB CONFIG
##
###############################################################################

