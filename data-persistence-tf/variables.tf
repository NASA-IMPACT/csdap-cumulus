variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "elasticsearch_config" {
  description = "Configuration object for Elasticsearch"
  type = object({
    domain_name    = string
    instance_count = number
    instance_type  = string
    version        = string
    volume_size    = number
  })
  default = {
    domain_name    = "es"
    instance_count = 1
    instance_type  = "t2.small.elasticsearch"
    version        = "5.3"
    volume_size    = 10
  }
}

variable "include_elasticsearch" {
  type    = bool
  default = true
}

variable "prefix" {
  type = string
}

variable "rds_cluster_remote_state_config" {
  type = object({ bucket = string, key = string, region = string })
}
