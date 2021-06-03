# CSDAP Cumulus Deployment

## Prerequisites

### Install `tfenv` and Terraform

[Install tfenv], which you will then use to install Terraform.

Once you have installed `tfenv`, install the version of Terraform specified in
the `.terraform-version` file by running the following command at the root of
this repository:

```bash
tfenv install
```

To confirm that `terraform` commands will now use the expected Terraform
version, run the following command:

```bash
terraform version
```

| IMPORTANT |
| :-------- |
| You may see a warning message regarding `terraform` being out of date.  Ignore this warning and do _not_ upgrade to the indicated version, as using a version other than the version specified in the `.terraform-version` file may cause compatibility issues when deploying Cumulus.

### Install and Configure the AWS CLI

[Install AWS CLI v2] (if not already installed) so that you can create an
AWS configuration entry for a new AWS profile to use for this project.

Once you have installed the AWS CLI, you must generate short-term access keys
using the [NGAP cloudtamer.io portal] by doing the following after logging into
the portal:

1. Locate the correct project and click the corresponding **Cloud access** button

1. Select the appropriate **account** (there may be only one account listed)

1. Select the appropriate **cloud access role**

1. Select **Short-term Access Keys**

1. In the dialog box that appears, under the section
   **Option 2: Add a profile to your AWS credentials file**, you should see
   credentials similar to the following:

   ```plain
   [123456789012_NGAPShApplicationDeveloper]
   aws_access_key_id=********************
   aws_secret_access_key=****************************************
   aws_session_token=********************************************
   ```

1. Hover your mouse over the credentials until the message
   **Click to copy this text** appears, then click the area to copy the
   credentials to your clipboard (the message should then change to **Copied!**)

Store the credentials you just copied to your clipboard as follows:

1. Using a text editor on your workstation, open the file
  `$HOME/.aws/credentials`, paste the contents of the clipboard into your
  editor, and change the name of the auto-generated profile, which will be
  something like `123456789012_NGAPShApplicationDeveloper`, to something simpler
  (e.g., `csdap-uat`).

1. Save and close the file.

1. Set the region for your newly created profile by running the following
   command, replacing `<profile>` with the name of your new profile (e.g.,
   `csdap-uat`) and `<region>` with the appropriate region (e.g., `us-west-2`):

   ```plain
   aws configure set --profile <profile> region <region>
   ```

1. Confirm that your new profile is correctly configured by running the following
   command:

   ```bash
   AWS_PROFILE=<profile> aws s3 sts get-caller-identity
   ```

   which should produce output similar to the following:

   ```json
   {
     "UserId": "*********************:<username>",
     "Account": "123456789012",
     "Arn": "arn:aws:sts::123456789012:assumed-role/NGAPShApplicationDeveloper/<username>"
   }
   ```

| NOTE |
| :--- |
| Unfortunately, for the time being, you must **periodically repeat the steps above**, whenever you attempt to run an AWS CLI command or deploy Cumulus (see below) and you encounter an "expired token" error message.

### Initialize Environment Variables

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Open `.env` in a text editor and set values as follows:

1. `AWS_PROFILE`: specify the name of the AWS profile you created in the
   previous section
1. `AWS_REGION`: specify the AWS region you configured in the previous section
1. `PREFIX`: a unique value that distinguishes your Cumulus AWS resources from
   those used for other Cumulus deployments within the same AWS account.
   Typically, this is some form of your name/nickname/initials, but can be
   anything unique to you (and should _not_ be any type of "secret" value)

**NOTE:** This file is ignored by `git`, so it will _not_ be committed to source
control.

Once you have saved your `.env` file with appropriate values, you may then use
the `dotenv` bash script (see below) to run other commands that use the
environment variables in your `.env` file.

Doing so allows you to use the values specified in your `.env` file without
exporting the environment variables when you want to avoid setting values that
might conflict with other projects on your machine, particularly your values for
`AWS_PROFILE` and `AWS_REGION`.

### Initialize Terraform Configuration

1. Create backend resources required by Terraform:

    ```bash
    ./dotenv ./setup-tf-backend-resources.sh
    ```

1. Set variables in `cumulus-tf/terraform.tfvars` as necessary.
   Guidance on specific variables:

   - `api_users`: Comma-separated list of double-quoted Earthdata Login
     usernames (enclosed in square brackets) that should be allowed to access
     your Cumulus API.  For a development deployment, this typically consists
     of only your own username (e.g., `["username1"]`).
   - `urs_client_id` / `urs_client_password`: Earthdata application credentials
     used to handle OAuth2 authentication for the Cumulus API.  In order to
     obtain such credentials, you must first [register an Earthdata Login
     application].

## Regular Deployment

### Deploy the `data-persistence` Module

To deploy the data-persistence module, which must be deployed at least once
prior to the first time the cumulus module is deployed (see below):

1. Change directory to `data-persistence-tf`
1. Run `../dotenv terraform init -reconfigure`
1. Run `../dotenv terraform apply`

### Deploy the `cumulus` Module

The `cumulus` module depends on the `data-persistence` module, so the
`data-persistence` module must be deployed at least once prior to deploying the
`cumulus` module.  To deploy the `cumulus` module:

1. Change directory to `cumulus-tf`
1. Run `../dotenv terraform init -reconfigure`
1. Run `../dotenv terraform apply`

[Install tfenv]:
    https://github.com/tfutils/tfenv
[Install AWS CLI v2]:
    https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
[register an Earthdata Login application]:
    https://nasa.github.io/cumulus/docs/deployment/deployment-readme#configure-earthdata-application
[NGAP cloudtamer.io portal]:
    https://cloud.earthdata.nasa.gov
