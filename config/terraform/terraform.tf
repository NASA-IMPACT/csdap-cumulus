terraform {
  required_version = "1.12.2"
  required_providers {
    archive = {
      source  = "hashicorp/archive",
      version = "~> 2.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100, < 6.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}
