#-------------------------------------------------------------------------------
# REQUIRED
#-------------------------------------------------------------------------------

variable "prefix" {
  type = string
}

#-------------------------------------------------------------------------------
# OPTIONAL
#-------------------------------------------------------------------------------

variable "aws_profile" {
  type    = string
  default = null
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "permissions_boundary_name" {
  type    = string
  default = "NGAPShRoleBoundary"
}
