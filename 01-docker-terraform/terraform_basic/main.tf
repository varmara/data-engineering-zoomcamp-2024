terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.13.0"
    }
  }
}

provider "google" {
# Credentials only needs to be set if you do not have the GOOGLE_APPLICATION_CREDENTIALS set
#  credentials = 
  project = "plasma-bison-411917"
  region = "europe-west1-b"
}



resource "google_storage_bucket" "demo-bucket" {
  name          = "dezoomcamp-plasma-bison-411917-terraform-bucket"
  location      = "EUROPE-WEST1"

  # Optional, but recommended settings:
  storage_class = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled     = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  // days
    }
  }

  force_destroy = true
}


resource "google_bigquery_dataset" "dataset" {
  dataset_id = "nytaxidata"
  project    = "plasma-bison-411917"
  location   = "EUROPE-WEST1"
}
