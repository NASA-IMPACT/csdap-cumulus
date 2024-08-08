#!/bin/bash

echo ""
echo "post-deploy-mods.sh: STARTED"

# About to call zip lambdas
ZIP_LAMBDAS_PATH="app/stacks/post-deploy-mods/resources/lambdas/pre-filter-DistributionApiEndpoints/zip_lambda.sh"
echo "post-deploy-mods.sh: About to call zip_lambda.sh at path: $ZIP_LAMBDAS_PATH"
sh "$ZIP_LAMBDAS_PATH"

echo "post-deploy-mods.sh: ENDED"
echo ""
