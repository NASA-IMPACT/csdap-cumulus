variable "max_capacity" {
  type    = number
  default = 2
}

variable "min_capacity" {
  type    = number
  default = 1
}

# Note, this started being used during the upgrade to 18.5.0
variable "snapshot_identifier" {
  description = "The identifier for the final snapshot for serverless 2 upgrade"
  type    = string
  default = ""
}