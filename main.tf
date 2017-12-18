
######################################
## Configure the Google Cloud provider
#
#  Connect to GCP and create a GKE (Google Container Engine) instance


provider "google" {
  credentials = "${file("terraform-admin.json")}"
  project     = "${var.gcp_project}"
  region      = "${var.gcp_region}"
}

## find zones for our configured region
#  https://www.terraform.io/docs/providers/google/d/google_compute_zones.html
#  capture with ${data.google_compute_zones.available.names[count.index]}
data "google_compute_zones" "available" {}

## create GKE Google Container Engine (Kubernettes)
resource "google_container_cluster" "kube" {
  name               = "marcellus-wallace"
  zone               = "${data.google_compute_zones.available.names[0]}"
  initial_node_count = 3

  node_config {
    service_account = "terraform@brockp-terraform-admin.iam.gserviceaccount.com"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}




#######################################
## Configure kubernetes provider and create service account for use with PODs
#
# start container on the created cluster kube
#
provider "kubernetes" {
  host     = "https://${google_container_cluster.kube.endpoint}"
  client_certificate = "${base64decode(google_container_cluster.kube.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.kube.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.kube.master_auth.0.cluster_ca_certificate)}"
}

########################################
## Pull in jupyterhub deffinition
#
#

module "jupyterhub" {
  source = "./jupyterhub"

  # Pass in config file from config.tf
  jupyterhub-config = "${kubernetes_config_map.jupyterhub-config.metadata.0.name}"
}


########################################
## Pull in NFS server on Kubernetes deffinition
#
#

module "kube-nfs" {
  source = "./kube-nfs"
}
