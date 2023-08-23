locals {
  aws_account_id           = data.aws_caller_identity.current.account_id
  permissions_boundary_arn = "arn:aws:iam::${local.aws_account_id}:policy/${var.permissions_boundary_name}"
}
