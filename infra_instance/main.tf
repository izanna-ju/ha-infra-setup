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

provider "aws" {
  region = "us-east-1"
}

locals {
  environment_name = terraform.workspace
}

variable "endpoint" {
  type      = string
  sensitive = true
}

module "infrastructure_instance" {
  source = "../module_infra"

  # input variables
  bucket_name      = "izanna-web-bucket"
  environment_name = local.environment_name
  endpoint         = var.endpoint
  region           = "us-east-1"
}

output "load_balancer_dns_name" {
  description = "DNS name of ALB"
  value       = module.infrastructure_instance.load_balancer_dns_name
}
