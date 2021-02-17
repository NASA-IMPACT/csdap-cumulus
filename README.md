# CSDAP - Cumulus deployment

## Prerequisites

- [`tfenv`](https://github.com/tfutils/tfenv)

## Install Terraform

Install the specified version of Terraform to use for deployment:

```plain
tfenv install
```

The version of Terraform used for this project can be found in the
`.terraform-version` file at the root of this repository.  This file is
automatically used by `tfenv` to ensure that all `terraform` commands executed
within this repository use the version of Terraform specified in that file.

To confirm that `terraform` commands will now use the expected Terraform
version, run the following command:

```plain
terraform version
```

## Choose a deployment prefix

A prefix value is used to uniquely identify your Cumulus deployment and namespace your Cumulus resources.

If you want to create your own deployment, you can use any arbitrary value, though it cannot collide with the prefix of any existing Cumulus deployments in the account that you are targeting.

If you want to update an existing deployment, such as the CSDAP UAT or SIT deployments that may already exist, consult a team member for the appropriate value to use.

Once you have decided on your prefix value, export it as an environment variable:

```bash
export PREFIX=<your-prefix>
```

## First-time deployment

> Note: These steps are only necessary for the first time you set up this deployment
> repo on your machine

### Create Terraform backend resources

```bash
./setup-tf-backend-resources.sh
```

### Create configuration files

1. Copy example backend configuration and variable files:

    ```bash
    cp data-persistence-tf/terraform.tf.example data-persistence-tf/terraform.tf
    cp data-persistence-tf/terraform.tfvars.example data-persistence-tf/terraform.tfvars
    cp cumulus-tf/terraform.tf.example cumulus-tf/terraform.tf
    cp cumulus-tf/terraform.tfvars.example cumulus-tf/terraform.tfvars
    ```

2. Replace all instances of `PREFIX` in the newly created files with [the value determined in a previous step](#choose-a-deployment-prefix)
3. Update other variables in `cumulus-tf/terraform.tfvars` as necessary. Guidance on specific variables:

      - `urs_client_id` / `urs_client_password` - These are values for an Earthdata application used to handle OAuth-2 authentication for the Cumulus API. See the Cumulus documentation for [guidance on how to create an application](https://nasa.github.io/cumulus/docs/deployment/deployment-readme#configure-earthdata-application).
      - `thin_egress_jwt_secret_name` - This is used by the Thin Egress App to manage authentication with Earthdata login. See the [Thin Egress App documentation how to create this secret](https://github.com/asfadmin/thin-egress-app#jwt-cookie-secret).

## Regular Deployment

### Deploy `data-persistence-tf`

1. `terraform init`
2. `terraform apply`

### Deploy `cumulus-tf`

1. `terraform init`
2. `terraform apply`
