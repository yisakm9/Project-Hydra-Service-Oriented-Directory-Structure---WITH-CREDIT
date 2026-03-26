variable "project_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "gcp_project_id" {
  description = "GCP Project ID for IAM bindings"
  type        = string
}
variable "gcs_bucket_name" {
  description = "Name of the GCS bucket to grant access to"
  type        = string
}
