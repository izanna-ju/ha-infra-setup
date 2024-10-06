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
  profile = "iamadmin-general"
}

