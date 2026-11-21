terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Codevern-Cloud-PC"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Owner       = "Codevern Management"
      Version     = "1.0"
    }
  }
}
