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

## Deployment

### Setup Terraform backends

> Note: These steps are only necessary for the first time you set up this deployment
> repo on your machine

1. Copy example backend configuration for data-persistence:

    ```bash
    cp data-persistence-tf/terraform.tf.example data-persistence-tf/terraform.tf
    ```

2. Replace `PREFIX` in `data-persistence-tf/terraform.tf` configuration with correct value
3. Copy example backend configuration for cumulus:

    ```bash
    cp cumulus-tf/terraform.tf.example cumulus-tf/terraform.tf
    ```

4. Replace `PREFIX` in `data-persistence-tf/terraform.tf` configuration with correct value

### Deploy `data-persistence-tf`

1. `terraform init`
2. Copy and update example variables:

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

3. `terraform apply`
