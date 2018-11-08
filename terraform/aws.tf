provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

terraform {
  backend "s3" {
    bucket = "production-tonic-terraform-state"
    key    = "production/tonic/coreos/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
