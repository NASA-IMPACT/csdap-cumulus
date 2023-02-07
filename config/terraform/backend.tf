terraform {
  backend "s3" {
    region         = "<%= expansion(':REGION') %>"
    bucket         = "<%= bucket('tfstate') %>"
    key            = "<%= expansion(':ENV/:MOD_NAME/terraform.tfstate') %>"
    encrypt        = true
    dynamodb_table = "<%= expansion('cumulus-:ENV-tfstate-locks') %>"
  }
}
