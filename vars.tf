variable "gcp_region" {
  description = "The region to place the cluster"
  default     = "us-central1"
}

variable "gcp_project" {
  description = "Google Project to invoke under"
  default     = "brockp-terraform-admin"
}

## Configuration file for jupyterhub
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
c.KubeSpawner.start_timeout=600

# Which container to spawn
c.KubeSpawner.singleuser_image_spec='jupyterhub/singleuser:0.8'
c.KubeSpawner.singleuser_service_account='default'
c.KubeSpawner.user_storage_pvc_ensure=True
c.KubeSpawner.debug=True

# mount in the NFS server to keep notebooks and data around between sessions
c.KubeSpawner.volumes=[
  {
    'name': 'nfs-volume', 
    'persistentVolumeClaim': {
      'claimName': '${kubernetes_persistent_volume.nfs-volume.metadata.0.name}'
    }
  }
 ]
c.KubeSpawner.volume_mounts=[
  {
    'name':'nfs-volume',
    'mountPath':'/mnt/'
  }
 ]

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
