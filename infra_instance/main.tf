terraform {
  backend "s3" {
    key = "infra/infra-setup/terraform.tfstate"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  environment_name = terraform.workspace
}

provider "aws" {
  region = "us-east-1"
}

module "infrastructure_instance" {
  source = "../module_infra"

  # input variables
  bucket_name      = "izanna-web-bucket"
  environment_name = local.environment_name
}

