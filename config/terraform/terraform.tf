terraform {
  required_version = "0.13.6"
  required_providers {
    archive = {
      source  = "hashicorp/archive",
      version = "~> 2.2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.14.1"
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
      version = "~> 2.3"
    }
  }
}
