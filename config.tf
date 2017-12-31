###############################################################################
##
# DO NOT NORMALLY EDIT THESE FILES
#    see: https://www.terraform.io/docs/configuration/variables.html Variable Files
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

  #  default = {
  #     cert = "${file("ssl/rajrao.gcp.arc-ts.umich.edu.cert")}"
  #     key = "${file("ssl/rajrao.gcp.arc-ts.umich.edu.key")}"
  #  }
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
c.JupyterHub.authenticator_class='dummyauthenticator.DummyAuthenticator'

## TODO Place other auth options here

# standard options Don't change
c.JupyterHub.allow_named_servers=True
c.JupyterHub.ip='0.0.0.0'
c.JupyterHub.hub_ip='0.0.0.0'
c.JupyterHub.cleanup_servers=False

# Don't start the Proxy 
c.ConfigurableHTTPProxy.should_start=False

EOM
  }
}

###############################################################################
## 
#   END JUPYTERHUB CONFIG
##
###############################################################################

