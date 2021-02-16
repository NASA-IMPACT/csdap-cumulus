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

### Deploy `data-persistence-tf`

1. cd `data-persistence-tf`
2. Copy example backend configuration and replace all instances of `PREFIX` with `***REMOVED***`:

    ```bash
    cp terraform.tf.example terraform.tf
    ```

3. `terraform init`
4. Copy example variables;

    ```bash
    cp terraform.tfvars.example terraform.tfvars
    ```

5. `terraform apply`
