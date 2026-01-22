# Configures the AWS provider and remote state storage

provider "aws" {
    region="eu-west-2"

    default_tags {
      tags = {
        Project = "Currency Exchange Orchestration"
        Environment = "Dev"
      }
    }
}

terraform {
    backend "s3" {
      region = "eu-west-2"
      bucket= "${var.s3-backend}"
      key = "ce-statefile"
    }
}