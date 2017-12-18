terraform {
  backend "gcs" {
    bucket  = "brockp-terraform-admin"
    prefix  = "/terraform.tfstate"
    project = "brockp-terraform-admin"
  }
}
