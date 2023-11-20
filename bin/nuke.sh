#!/usr/bin/env bash

set -Eeuo pipefail
trap 'retry $? $LINENO' ERR

_confirmation_phrase="destroy ${TS_ENV}"
_attempts=${1:-1}

retry() {
  echo
  echo -n "ERROR ${1} on line ${2}.  "

  if [[ ${_attempts} -ge 10 ]]; then
    echo "Giving up after ${_attempts} attempts."
    exit "${1}"
  else
    echo "Retrying..."
    echo
    "${BASH_SOURCE[0]}" $((_attempts + 1)) <<<"${_confirmation_phrase}"
    exit 0
  fi
}

echo ""
echo ">>> DANGER! <<<"
echo ""
echo "Proceeding with this operation will"
echo "COMPLETELY DESTROY THE FOLLOWING DEPLOYMENT:"
echo ""
echo "    AWS_PROFILE: ${AWS_PROFILE}"
echo "    TS_ENV:      ${TS_ENV}"
echo ""
echo "If you wish to proceed, type the following at the prompt:"
echo ""
echo "    ${_confirmation_phrase}"
echo ""
read -rp "Only '${_confirmation_phrase}' will be accepted for approval: " _reply
echo ""

if [[ ${_reply} != "${_confirmation_phrase}" ]]; then
  echo "Operation ABORTED."
  echo ""
  exit 0
fi

export TS_BUFFER_TIMEOUT=14400
set -x

_dynamo_db_tables=$(
  aws dynamodb list-tables --query '*' --output text |
    tr '\t' '\n' |
    { grep "${CUMULUS_PREFIX}-.*Table" || true; }
)
_active_dynamo_db_tables=()

for _table in ${_dynamo_db_tables}; do
  if [[ "$(aws dynamodb describe-table --table-name "${_table}" --output text --query Table.TableStatus)" = "ACTIVE" ]]; then
    _active_dynamo_db_tables+=("${_table}")
  fi
done

# If any "ACTIVE" DynamoDB tables exist, destroy the cumulus module as well as the
# tables.  This check also allows this script to be re-run without issue in the
# event that something went wrong.
if [[ -n "${_active_dynamo_db_tables[*]}" ]]; then
  terraspace down cumulus -y

  for _table in "${_active_dynamo_db_tables[@]}"; do
    aws dynamodb delete-table --table-name "${_table}" || true
  done
fi

_rds_cluster_ids=$(
  aws rds describe-db-clusters \
    --query "DBClusters[?contains(DBClusterIdentifier, '${CUMULUS_PREFIX}')].DBClusterIdentifier" \
    --output text
)

# If the RDS Cluster exists, destroy the data-persistence module as well as the
# cluster.  This check also allows this script to be re-run without issue in the
# event that something went wrong.
if [[ -n "${_rds_cluster_ids}" ]]; then
  terraspace init data-persistence
  terraspace init rds-cluster
  terraspace down data-persistence -y

  for _rds_cluster_id in ${_rds_cluster_ids}; do
    aws rds modify-db-cluster \
      --no-cli-pager \
      --no-deletion-protection \
      --db-cluster-identifier "${_rds_cluster_id}"
    aws rds delete-db-cluster \
      --no-cli-pager \
      --skip-final-snapshot \
      --db-cluster-identifier "${_rds_cluster_id}"
  done

  terraspace down rds-cluster -y
fi

#-------------------------------------------------------------------------------
# Destroy the rest of the infrastructure not managed by Terraform.
#-------------------------------------------------------------------------------

# Delete all SSM parameters for TS_ENV

aws ssm describe-parameters \
  --parameter-filters "Key=Name,Option=Contains,Values=/${TS_ENV}/" \
  --query Parameters[].Name \
  --output text |
  tr '\t' '\n' |
  xargs -r -L1 -t aws ssm delete-parameter --name

# Delete all CloudWath Log Groups for TS_ENV

aws logs describe-log-groups \
  --log-group-name-pattern="${CUMULUS_PREFIX}" \
  --output text \
  --query logGroups[].logGroupName |
  tr '\t' '\n' |
  xargs -r -L1 -t aws logs delete-log-group --log-group-name

# Delete all REST API Gateway deployments for TS_ENV

aws apigateway get-rest-apis \
  --output text \
  --query "items[?contains(name, '${CUMULUS_PREFIX}')].id" |
  tr '\t' '\n' |
  xargs -r -L1 -t aws apigateway delete-rest-api --rest-api-id

#-------------------------------------------------------------------------------
# Issue another confirmation prompt before emptying and destroying buckets.
#-------------------------------------------------------------------------------

_buckets=$(
  aws s3api list-buckets \
    --output text \
    --query "Buckets[?contains(Name, '${TS_ENV}')].Name" |
    tr '\t' '\n'
)

set +x

_confirmation_phrase="destroy ${TS_ENV} buckets"

echo ""
echo ">>> DANGER! <<<"
echo ""
echo "Proceeding with this operation will"
echo "COMPLETELY EMPTY AND DESTROY THE FOLLOWING BUCKETS:"
echo ""
echo "${_buckets}"
echo ""
echo "If you wish to proceed, type the following at the prompt:"
echo ""
echo "    ${_confirmation_phrase}"
echo ""
read -rp "Only '${_confirmation_phrase}' will be accepted for approval: " _reply
echo ""

if [[ ${_reply} != "${_confirmation_phrase}" ]]; then
  echo "Operation ABORTED."
  echo ""
  exit 0
fi

set -x

# Since the tfstate bucket has objects with versioning enabled, we need to explicitly
# delete the versioned objects before we can delete the bucket.  Specifically, using the
# --force flag with the `aws s3 rb` command will not work when versioning is enabled,
# thus requiring explicit deletion of the versioned objects first.

# shellcheck disable=SC2016
aws s3api list-buckets \
  --output text \
  --query "Buckets[?contains(Name, '${TS_ENV}') && contains(Name, 'tfstate')].Name" |
  tr '\t' '\n' |
  xargs -r -t -I{} sh -c 'aws s3api delete-objects --no-paginate --bucket "${1}" --delete "$(
    aws s3api list-object-versions \
      --bucket "${1}" \
      --no-paginate \
      --output=json \
      --query="{Objects: Versions[].{Key:Key,VersionId:VersionId}}"
    )" || true' -- {}

# Now we must delete the bucket lifecycle configuration for the tfstate bucket to allow
# us to delete the "delete markers" that AWS created during the previous step.

aws s3api list-buckets \
  --output text \
  --query "Buckets[?contains(Name, '${TS_ENV}') && contains(Name, 'tfstate')].Name" |
  tr '\t' '\n' |
  xargs -r -L1 -t aws s3api delete-bucket-lifecycle --bucket

# Now we can delete the "delete markers" that AWS created.

# shellcheck disable=SC2016
aws s3api list-buckets \
  --output text \
  --query "Buckets[?contains(Name, '${TS_ENV}') && contains(Name, 'tfstate')].Name" |
  tr '\t' '\n' |
  xargs -r -t -I{} sh -c 'aws s3api delete-objects --no-paginate --bucket "${1}" --delete "$(
    aws s3api list-object-versions \
      --bucket "${1}" \
      --no-paginate \
      --output=json \
      --query="{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}"
    )" || true' -- {}

# Finally, we can delete all of the buckets for TS_ENV.  We include the --force flag
# to automatically delete all objects in each bucket before deleting the bucket itself,
# exluding the objects in the tfstate bucket, which we already deleted above.

aws s3api list-buckets \
  --output text \
  --query "Buckets[?contains(Name, '${TS_ENV}')].Name" |
  tr '\t' '\n' |
  xargs -r -t -I{} aws s3 rb s3://{} --force
