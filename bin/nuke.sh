#!/usr/bin/env bash

set -euo pipefail

_confirmation_phrase="destroy ${TS_ENV}"

echo ""
echo ">>> DANGER! <<<"
echo ""
echo "Proceeding with this operation will"
echo "COMPLETELY DESTROY THE FOLLOWING DEPLOYMENT"
echo "(given by the TS_ENV environment variable):"
echo ""
echo "    ${TS_ENV}"
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

terraspace down cumulus -y

aws dynamodb list-tables --query '*' --output text |
  tr '\t' '\n' |
  grep "${CUMULUS_PREFIX}-.*Table" |
  xargs -L1 aws dynamodb delete-table --table-name

terraspace down data-persistence -y

_rds_cluster_id=$(
  aws rds describe-db-clusters \
    --query "DBClusters[?contains(DBClusterIdentifier, '${CUMULUS_PREFIX}')].DBClusterIdentifier" \
    --output text
)

AWS_PAGER="" aws rds modify-db-cluster \
  --no-deletion-protection \
  --db-cluster-identifier "${_rds_cluster_id}"
AWS_PAGER="" aws rds delete-db-cluster \
  --skip-final-snapshot \
  --db-cluster-identifier "${_rds_cluster_id}"

terraspace down rds-cluster -y
