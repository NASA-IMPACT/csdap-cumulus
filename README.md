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

## First-time deployment

> Note: These steps are only necessary for the first time you set up this deployment
> repo on your machine

### Create Terraform backend resources

See <https://nasa.github.io/cumulus/docs/deployment/deployment-readme#create-resources-for-terraform-state>

### Create configuration files

1. Copy example backend configuration and variable files:

    ```bash
    cp data-persistence-tf/terraform.tf.example data-persistence-tf/terraform.tf
    cp data-persistence-tf/terraform.tfvars.example data-persistence-tf/terraform.tfvars
    cp cumulus-tf/terraform.tf.example cumulus-tf/terraform.tf
    cp cumulus-tf/terraform.tfvars.example cumulus-tf/terraform.tfvars
    ```

2. Replace all instances of `PREFIX` in `data-persistence-tf/terraform.tf` and `cumulus-tf/terraform.tf` configuration with correct value

## Regular Deployment

### Initialize variables

```bash
export PREFIX=<your-prefix>
source ./init-tf-vars.sh
```

If you are unsure what value to use for `PREFIX`, ask a fellow team member.

### Deploy `data-persistence-tf`

1. `terraform init`
2. `terraform apply`
