terraform {
  backend "gcs" {
    # GCP Bucket to hold state 
    bucket = "brockp-terraform-admin"

    # folder in bucket to hold state, this must be unique across installs
    # Buckets can be shared, but not prefix
    prefix = "/terraform.tfstate"

    # GCP Project
    project = "brockp-terraform-admin"
  }
}
