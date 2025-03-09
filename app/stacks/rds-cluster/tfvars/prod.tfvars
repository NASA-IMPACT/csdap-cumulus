# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster

# These are old vars for serverless v1 - Cumulus v18.4.0 and below.
# In the near future, we may need to fine tune these for the ingest runs using serverless v2 
#min_capacity = 2
#max_capacity = 128 # 384 (note, using 384 will break the Serverless v2 upgrade on prod..)
