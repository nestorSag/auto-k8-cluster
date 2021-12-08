terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region = var.backend-region
    key    = "terraform-state-file"
    bucket = var.backend-bucket
  }
}