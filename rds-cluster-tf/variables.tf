variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = null
}

variable "db_admin_username" {
  description = "Username for RDS database authentication"
  type        = string
  default     = "postgres"
}

variable "deletion_protection" {
  description = "Flag to prevent terraform from making changes that delete the database in CI"
  type        = bool
  default     = true
}

variable "engine_version" {
  description = "Postgres engine version for Serverless cluster"
  type        = string
  default     = "10.14"
}

variable "permissions_boundary_name" {
  type    = string
  default = ""
}

variable "prefix" {
  type = string
}

variable "provision_user_database" {
  description = "true/false flag to configure if the module should provision a user and database using default settings"
  type        = bool
  default     = false
}

variable "region" {
  description = "Region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "snapshot_identifier" {
  description = "Optional database snapshot for restoration"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to be applied to RDS cluster resources that support tags"
  type        = map(string)
  default     = {}
}
