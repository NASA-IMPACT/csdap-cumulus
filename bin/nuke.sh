#!/usr/bin/env bash

set -euo pipefail

_confirmation_phrase="destroy ${TS_ENV}"

echo ""
echo ">>> DANGER! <<<"
echo ""
echo "Proceeding with this operation will"
echo "COMPLETELY DESTROY THE FOLLOWING DEPLOYMENT:"
echo ""
echo "    AWS_PROFILE: ${AWS_PROFILE}"
echo "    TS_ENV:      ${TS_ENV}"
echo ""
echo "If you wish to proceed, type the following at"
echo "the prompt:"
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

# If any DynamoDB tables exist, destroy the cumulus module as well as the
# tables.  This check also allows this script to be re-run without issue in the
# event that something went wrong.
if [[ -n "${_dynamo_db_tables}" ]]; then
  terraspace down cumulus -y

  for _table in ${_dynamo_db_tables}; do
    aws dynamodb delete-table --table-name "${_table}"
  done
fi

_rds_cluster_id=$(
  aws rds describe-db-clusters \
    --query "DBClusters[?contains(DBClusterIdentifier, '${CUMULUS_PREFIX}')].DBClusterIdentifier" \
    --output text
)

# If the RDS Cluster exists, destroy the data-persistence module as well as the
# cluster.  This check also allows this script to be re-run without issue in the
# event that something went wrong.
if [[ -n "${_rds_cluster_id}" ]]; then
  terraspace down data-persistence -y

  AWS_PAGER="" aws rds modify-db-cluster \
    --no-deletion-protection \
    --db-cluster-identifier "${_rds_cluster_id}"
  AWS_PAGER="" aws rds delete-db-cluster \
    --skip-final-snapshot \
    --db-cluster-identifier "${_rds_cluster_id}"
fi

terraspace down rds-cluster -y
