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
resource "google_container_cluster" "arcts-kube" {
  name               = "${var.gke_options["name"]}"
  zone               = "${lookup(var.gke_options, "zone", "${data.google_compute_zones.available.names[0]}")}"
  initial_node_count = "${var.gke_options["initial_node_count"]}"

  node_config {
    #service_account = "terraform@brockp-terraform-admin.iam.gserviceaccount.com"
    preemptible  = "${lookup(var.gke_options, "preemptible", "false")}"
    disk_size_gb = "${lookup(var.gke_options, "disk_size_gb", "10")}"
    machine_type = "${lookup(var.gke_options, "machine_type", "n1-standard-1")}"

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
# start container on the created cluster arcts-kube
#
provider "kubernetes" {
  host                   = "https://${google_container_cluster.arcts-kube.endpoint}"
  client_certificate     = "${base64decode(google_container_cluster.arcts-kube.master_auth.0.client_certificate)}"
  client_key             = "${base64decode(google_container_cluster.arcts-kube.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.arcts-kube.master_auth.0.cluster_ca_certificate)}"
}

########################################
## Pull in jupyterhub deffinition
#
#

module "jupyterhub" {
  source = "./jupyterhub"

  # Pass in config file from config.tf
  jupyterhub-config = "${kubernetes_config_map.jupyterhub-config.metadata.0.name}"
  ssl_cert          = "${var.ssl_cert}"
}

output "jupyterhub_public_ip" {
  value = "${module.jupyterhub.jupyter_service_lbip}"
}

########################################
## Pull in NFS server on Kubernetes deffinition
#
#

module "kube-nfs" {
  source = "./kube-nfs"
}

###########################
## Assign DNS to jupyterhub
#
resource "google_dns_record_set" "jupyterhub-lb" {
  count = "${var.enable_dns}"
  name  = "${var.dns_name}"
  type  = "A"
  ttl   = 300

  managed_zone = "${var.dns_zone}"

  rrdatas = ["${module.jupyterhub.jupyter_service_lbip}"]
}
