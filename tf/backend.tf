terraform {
  required_version = ">=0.12.0"
  backend "s3" {
    region = "us-west-2"
    key    = "terraform-state-file"
    bucket = "mlops-tf-bucket"
  }
}