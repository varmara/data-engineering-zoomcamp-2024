# NOT NEEDED IF CREDENTIALS ARE IN ENVIRONMENT VARIABLE
#variable "credentials" {
#  description = "My Credentials"
#  default     = "<Path to your Service Account json file>"
#  #ex: if you have a directory where this file is called keys with your service account json file
#  #saved there as my-creds.json you could use default = "./keys/my-creds.json"
#}


variable "project" {
  description = "Project"
  default     = "plasma-bison-411917"
}

variable "region" {
  description = "Region"
  #Update the below to your desired region
  default     = "europe-west1-b"
}

variable "location" {
  description = "Project Location"
  #Update the below to your desired location
  default     = "EUROPE-WEST1"
}

variable "bq_dataset_name" {
  description = "BigQuery dataset nytaxidata"
  #Update the below to what you want your dataset to be called
  default     = "nytaxidata"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  #Update the below to a unique bucket name
  default     = "dezoomcamp-plasma-bison-411917-terraform-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
