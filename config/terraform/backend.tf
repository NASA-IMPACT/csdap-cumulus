terraform {
  backend "s3" {
    region         = "<%= expansion(':REGION') %>"
    bucket         = "<%= expansion('csdap-cumulus-:INSTANCE-tf-state') %>"
    key            = "<%= expansion(':MOD_NAME/terraform.tfstate') %>"
    dynamodb_table = "<%= expansion('cumulus-:INSTANCE-tf-locks') %>"
    encrypt        = true
  }
}
