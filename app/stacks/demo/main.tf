# resource "random_pet" "this" {
#   length = 2
# }

# module "bucket" {
#   source = "../../modules/example"
#   bucket = "bucket-${random_pet.this.id}"
#   acl    = var.acl
# }

module "data_persistence" {
  source = "https://github.com/nasa/cumulus/releases/download/v8.1.0/terraform-aws-cumulus.zip//tf-modules/data-persistence"

  prefix                = var.prefix
  subnet_ids            = data.aws_subnet_ids.ngap_subnets.ids
  include_elasticsearch = var.include_elasticsearch

  elasticsearch_config = var.elasticsearch_config

  tags = {
    Deployment = var.prefix
  }
}
