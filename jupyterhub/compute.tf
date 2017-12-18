## Built on: http://danielfrg.com/blog/2016/09/03/jupyterhub-kubernetes-ldap/

# start service account for POD, this service account is for Kubernetes, not Google
resource "kubernetes_service_account" "example" {
  metadata {
    name = "terraform-example"
  }
  secret {
    name = "${kubernetes_secret.example.metadata.0.name}"
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name = "terraform-example"
  }
}

## assign the container "pod" 
resource "kubernetes_pod" "jupyterhub" {
  metadata {
    name = "jupyter-notebook"

    labels {
      app = "jupyter-app"
    }
  }

  spec {
    service_account_name = "${kubernetes_service_account.example.metadata.0.name}"

    container {
      image = "jupyterhub/configurable-http-proxy"
      name  = "proxy"
      port {
        container_port = 8000
      }
      port {
        container_port = 8001
      }
      command = [
        "configurable-http-proxy",
        "--ip",
        "0.0.0.0",
        "--api-ip",
        "0.0.0.0",
        "--default-target",
        "http://127.0.0.1:8081",
        "--error-target",
        "http://127.0.0.1:8081/hub/error",
      ]
    }

    container {
      image = "brockp/jupyterhub-k8s:0.2"
      name  = "hub"
      port {
        container_port = 8081
      }
      command = [
       "jupyterhub",
       "-f",
       "/srv/jupyterhub/config/jupyterhub-config.py"
      ]
      volume_mount {
        mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
        name       = "${kubernetes_service_account.example.default_secret_name}"
        read_only  = true
      }
      volume_mount {
        mount_path = "/srv/jupyterhub/config/"
        name       = "jupyterhub-config"
        read_only  = false
      }
    }

    container {
      image = "centos:latest"
      name  = "sleep"
      port {
        container_port = 8000
      }
      port {
        container_port = 8001
      }
      command = [
        "sleep",
        "3600",
      ]
    }

    volume {
      name = "${kubernetes_service_account.example.default_secret_name}"

      secret {
        secret_name = "${kubernetes_service_account.example.default_secret_name}"
      }
    }

    volume {
      name = "jupyterhub-config"

      config_map {
        name = "${kubernetes_config_map.jupyterhub-config.metadata.0.name}"
      }
    }
  }
}

resource "kubernetes_service" "jupyter-public" {
  metadata {
    name = "jupyter-public"
  }

  spec {
    selector {
      app = "${kubernetes_pod.jupyterhub.metadata.0.labels.app}"
    }

    port {
      port        = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}

## create a service that exposes the pod as part of a load balancer
resource "kubernetes_service" "hub-internal" {
  metadata {
    name = "jupyter-notebook"
  }

  spec {
    selector {
      app = "${kubernetes_pod.jupyterhub.metadata.0.labels.app}"
    }

    port {
      port = 8081
    }

    type = "ClusterIP"
  }
}

output "jupyter_service_lbip" {
  value = "${kubernetes_service.jupyter-public.load_balancer_ingress.0.ip}"
}

## Assign DNS to jupyterhub
resource "google_dns_record_set" "jupyterhub-lb" {
  #name = "jupyterhub-lb.${google_dns_managed_zone.prod.dns_name}"
  name = "jupyterhub.gcp.brockpalen.com."
  type = "A"
  ttl  = 300

  #managed_zone = "${google_dns_managed_zone.prod.name}"
  managed_zone = "gcp-brockpalen-com-zone"

  rrdatas = ["${kubernetes_service.jupyter-public.load_balancer_ingress.0.ip}"]
}

#######################################
## NFS Server for presistant notebooks
#######################################
resource "kubernetes_pod" "jupyter-nfs" {
  metadata {
    name = "jupyter-nfs"

    labels {
      app = "jupyter-nfs"
    }
  }

  spec {
    service_account_name = "${kubernetes_service_account.example.metadata.0.name}"

    container {
      image = "gcr.io/google-samples/nfs-server:1.1"
      name  = "jupyter-nfs-server"

      port {
        name           = "nfs"
        container_port = 2049
      }
      port {
        name           = "mountd"
        container_port = 20048
      }
      port {
        name           = "rpcbind"
        container_port = 111
      }

      volume_mount {
        mount_path = "/exports"
        name       = "nfs-export-volume"
      }

      security_context {
        privileged = true
      }
    }

    volume {
      name = "nfs-export-volume"

      persistent_volume_claim {
        claim_name = "${kubernetes_persistent_volume_claim.jupyterhub-storage-claim.metadata.0.name}"
      }
    }
  }
}

resource "kubernetes_storage_class" "example" {
  metadata {
    name = "terraform-example"
  }

  storage_provisioner = "kubernetes.io/gce-pd"

  parameters {
    type = "pd-standard"
  }
}

resource "kubernetes_persistent_volume_claim" "jupyterhub-storage-claim" {
  metadata {
    name = "jupyterhub-storage-claim"
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "${kubernetes_storage_class.example.metadata.0.name}"

    resources {
      requests {
        storage = "5Gi"
      }
    }
  }
}

## NFS Server Service
resource "kubernetes_service" "jupyter-nfs" {
  metadata {
    name = "jupyter-nfs"
  }

  spec {
    selector {
      app = "${kubernetes_pod.jupyter-nfs.metadata.0.labels.app}"
    }

    port {
      name = "nfs"
      port = 2049
    }

    port {
      name = "mountd"
      port = 20048
    }

    port {
      name = "rpcbind"
      port = 111
    }
  }
}

## NFS Server as persistent volume
resource "kubernetes_persistent_volume" "nfs-volume" {
  metadata {
    name = "nfs-volume"
  }

  spec {
    capacity {
      storage = "5Gi"
    }

    access_modes = ["ReadWriteMany"]

    persistent_volume_source {
      nfs {
        path   = "/exports"
        server = "${kubernetes_service.jupyter-nfs.metadata.0.name}"
      }
    }
  }
}

#resource "kubernetes_persistent_volume_claim" "nfs-volume" {
#  metadata {
#    name = "nfs-volume"
#  }
#
#  spec {
#    access_modes = ["ReadWriteMany"]
#    volume_name = "${kubernetes_persistent_volume.nfs-volume.metadata.0.name}"
##    storage_class_name = """"
#    resources {
#      requests {
#        storage = "5Gi"
#      }
#    }
#  }
#}

