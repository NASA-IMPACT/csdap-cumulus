output "admin_db_login_secret_arn" {
  value = module.rds_cluster.admin_db_login_secret_arn
}

output "admin_db_login_secret_version" {
  value = module.rds_cluster.admin_db_login_secret_version
}

output "rds_endpoint" {
  value = module.rds_cluster.rds_endpoint
}

output "security_group_id" {
  value = module.rds_cluster.security_group_id
}

output "user_credentials_secret_arn" {
  value = module.rds_cluster.user_credentials_secret_arn
}

# How do we output the password so that the Cumulus module can read it via
#
# # jsondecode("<%= json_output('rds-cluster.db_admin_password') %>")
# # jsondecode("<%= json_output('rds-cluster.rds_user_password') %>")
#
# This does not work... why..
#
# [2023-09-27T17:36:47 #29 terraspace up rds-cluster]: Error: Unsupported attribute
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:   on outputs.tf line 27, in output "rds_cluster_db_admin_password":
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:   27:   value = module.rds_cluster.db_admin_password
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]: This object does not have an attribute named "db_admin_password".
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:
#[2023-09-27T17:36:47 #29 terraspace up rds-cluster]:
#
#output "rds_cluster_db_admin_password" {
#  value = module.rds_cluster.db_admin_password
#}
##
#output "rds_cluster_rds_user_password" {
#  value = module.rds_cluster.rds_user_password
#}
