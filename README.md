# CSDAP Cumulus Deployment

## Overview

TODO

## Prerequisites

Although the instructions in this section may appear extensive, getting
everything set up should be reasonably straightforward.  The following
high-level steps are detailed in the following subsections:

1. Install `tfenv` and Terraform
1. Install and configure the AWS CLI
1. Initialize environment variables
1. Initialize Terraform configuration

Once you complete these prerequisite steps, you should be able to develop and
deploy this project's Cumulus system.

### Install `tfenv` and Terraform

We use Terraform to manage our Cumulus infrastructure in AWS.  To install the
correct version of Terraform, do the following:

1. [Install tfenv], which provides a convenient means of managing Terraform
   installations.

1. Install the version of Terraform specified in the `.terraform-version` file
   by running the following command at the root of this repository:

   ```bash
   tfenv install
   ```

1. Confirm that `terraform` commands will now use the expected Terraform
   version:

   ```bash
   terraform version
   ```

   | IMPORTANT |
   | :-------- |
   | You may see a warning message regarding `terraform` being out of date.  Ignore this warning and do _not_ upgrade to the indicated version, as using a version other than the version specified in the `.terraform-version` file may cause compatibility issues when deploying Cumulus.

With `tfenv` installed, and with `terraform` installed via `tfenv`, all
`terraform` commands executed from within the project repository structure will
use the version of `terraform` specified in the `.terraform-version` file, which
matches the version recommended by the current version of Cumulus that this
project uses.

### Install and Configure the AWS CLI

Since we use AWS, we must install the AWS CLI:

| INSTALL AWS CLI |
| :-------------- |
| [Install AWS CLI v2]. If you already have version 1 installed, that should suffice, but version 2 is strongly recommended if you don't already have a version installed.

With the AWS CLI installed, you must create an AWS _profile_ associated with
this project in order to run both AWS CLI and Terraform commands.  However, in
order to create an AWS profile, you must generate _access keys_ using the
[NGAP cloudtamer.io portal].

Ideally, if you have permission to do so, generate _long-term_ access keys (see
below), which should last for 90 days.  Otherwise, you'll have to generate
_short-term_ access keys on a _daily_ basis, which can quickly become annoying
(see farther below, but only if you are unable to generate long-term access
keys, as described next).

#### Generating Long-Term Access Keys

To generate **long-term access keys**, do the following, but if at any step,
something is not available to you, it is likely because you do not have
permission to generate long-term access keys, and must generate short-term
access keys instead, as described in the subsequent section.

1. Login to the [NGAP cloudtamer.io portal].
1. If the appropriate project is not visible, click **Projects** in the left
   navigation bar to see a list of all of your projects.
1. Click the appropriate project name/title (e.g., csdap-cumulus-uat-7469).
1. Along the top row of tabs/headers, click **CLOUD MANAGEMENT**.
1. Along the second row of tabs/headers, click **AWS Long-Term Access Keys**.
1. At the right of the (likely empty) list of AWS Long-Term Access Keys, click
   the small icon consisting of **3 vertically arranged dots**, to see a menu.
1. Click **Create AWS long-term access keys**.
1. In the **Generate API Key** dialog box, select the appropriate account and
   role, then click the **Generate API Key** button.
1. You should see a **Success!** dialog box with a visible **API Key ID** and a
   hidden **Secret Access Key**.  At this point, **leave this dialog box open**
   so we can copy the displayed values in a moment.

With the dialog box still open in the web portal, open a terminal window and
initiate creation of an AWS Profile to use with this project, by running the
following command, replacing `<profile>` with a name that matches the name of
the web portal project for which you just generated keys above (e.g.,
`csdap-cumulus-uat`):

```bash
aws configure --profile <profile>
```

You should be prompted with the following:

```plain
AWS Access Key ID [None]:
```

Go back to the **Success!** dialog box in the web portal, copy the value shown
for the **API Key ID**, paste it into the terminal prompt shown above, and press
Enter/Return, which should then prompt you as follows:

```plain
AWS Access Key ID [None]: AKIA****************
AWS Secret Access Key [None]:
```

Go back to the **Success!** dialog box one more time, click the **Show** link
at the right end of the string of asterisks to show your **Secret Access Key**.
Copy the visible secret access key, paste it into the terminal prompt shown
above, and press Enter/Return again, which should lead to the following
additional prompts:

```plain
AWS Access Key ID [None]: AKIA****************
AWS Secret Access Key [None]: a3***********************************73Z
Default region name [None]:
Default output format [None]:
```

At the **Default region name** prompt, enter the appropriate region (e.g.,
`us-west-2`).  At the **Default output prompt**, you can press Enter/Return for
the default, which is `json` (recommended, if not familiar with the other
formats).  Alternatively, you can use one of the following formats: `text`,
`table`, `yaml`, `yaml-stream`.

If you successfully generated long-term access keys, skip the next section.
However, if you were unable to perform any step above, you might not have
permission to do so, and you must generate short-term access keys as detailed
in the next section.

#### Generating Short-Term Access Keys

If you are (sadly) unable to generate long-term access keys as described above,
you must generate **short-term access keys** as follows:

1. Login to the [NGAP cloudtamer.io portal] (if not already logged in).
1. If the appropriate project is not visible, click **Projects** in the left
   navigation menu to see a list of all of your projects.
1. Locate the correct project and click the corresponding **Cloud access**
   button that appears to the (far) right of the project name.
1. Select the appropriate **account** (there may be only one account listed).
1. Select the appropriate **cloud access role**.
1. Select **Short-term Access Keys**.
1. You should see a dialog box with 3 options displayed.  At this point,
   **leave this dialog box open** so we can copy the displayed values in a
   moment.

With the dialog box still open in the web portal, open a terminal window and
initiate creation of an AWS Profile to use with this project, by running the
following command, replacing `<profile>` with a name that matches the name of
the web portal project for which you just generated keys above (e.g.,
`csdap-cumulus-uat`):

```bash
aws configure --profile <profile>
```

You should be prompted with the following:

```plain
AWS Access Key ID [None]:
```

Go back to the dialog box in the web portal, and towards the bottom, under
Option 3, copy the value shown for the **AWS LONG-TERM ACCESS KEY ID**, paste it
into the terminal prompt shown above, and press Enter/Return, which should then
prompt you as follows:

```plain
AWS Access Key ID [None]: ASIA****************
AWS Secret Access Key [None]:
```

Go back to the dialog box again, copy the value shown (under Option 3) for
**AWS SECRET ACCESS KEY**, paste it into the terminal prompt shown above, and
press Enter/Return again, which should lead to the following additional prompts:

```plain
AWS Access Key ID [None]: AKIA****************
AWS Secret Access Key [None]: a3***********************************73Z
Default region name [None]:
Default output format [None]:
```

At the **Default region name** prompt, enter the appropriate region (e.g.,
`us-west-2`).  At the **Default output prompt**, you can press Enter/Return for
the default, which is `json` (recommended, if not familiar with the other
formats).  Alternatively, you can use one of the following formats: `text`,
`table`, `yaml`, `yaml-stream`.

Go back to the dialog box a final time, copy the value shown for
**AWS SESSION TOKEN**, and run the following command, replacing `<profile>`
with the name of the profile you used above, and pasting the token you just
copied from the dialog box in place of `<token>`:

```plain
aws configure set --profile <profile> aws_session_token <token>
```

| NOTE |
| :--- |
| Unfortunately, if you are unable to create long-term access tokens, you must **periodically repeat the steps above**, whenever you attempt to run an AWS CLI or Terraform command and you encounter an "expired token" error message.

### Initialize Environment Variables

Copy `.env.example` to `.env` (the `-n` options prevents overwriting `.env` if
it already exists):

```bash
cp -n .env.example .env
```

Open `.env` in a text editor and set values as follows:

1. `AWS_PROFILE`: the name of the AWS profile you created in the previous
   section
1. `AWS_REGION`: the AWS region you configured in the previous section
1. `PREFIX`: a unique value that distinguishes your Cumulus AWS resources from
   those used for other Cumulus deployments within the same AWS account.
   Typically, this is some form of your name/nickname/initials, but can be
   anything unique to you (and should _not_ be any type of "secret" value)

**NOTE:** This file is ignored by `git`, so it will _not_ be committed to source
control so that it does not conflict with settings appropriate for others.

### Initialize Terraform Configuration

| OS X USERS |
| :--------- |
| You must install the `envsubst` utility.  If you have Homebrew installed, the easiest way to install the utility is by installing the `gettext` package by running `brew install gettext`.

First, create backend resources required by Terraform (for managing Terraform
state files):

```bash
./setup-tf-backend-resources.sh
```

Next, create Terraform configuration files (for configuring Cumulus Terraform
settings):

```bash
./setup-tf-config.sh
```

Finally, set variables in `cumulus-tf/terraform.tfvars` (created by the command
above) as necessary.  You may initially skip this step, if you wish to jump
directly to deploying Cumulus for the first time.

However, there are variables in `cumulus-tf/terraform.tfvars` that you will
need to set in order for certain parts of Cumulus to function properly after
deployment.  After setting/changing variables, you must redeploy Cumulus for
the changes to take effect.

Here is guidance on some specific variables in `cumulus-tf/terraform.tfvars`:

- `api_users`: Comma-separated list of double-quoted Earthdata Login
  usernames (enclosed in square brackets) that should be allowed to access
  your Cumulus API.  For a development deployment, this typically consists
  of only your own username (e.g., `["jdoe"]`) for the Earthdata Login
  at <https://uat.urs.earthdata.nasa.gov/>.
- `urs_client_id` / `urs_client_password`: Earthdata application credentials
  used to handle OAuth2 authentication for the Cumulus API.  In order to
  obtain such credentials, you must first [register an Earthdata Login
  application].
- `cmr_provider`, `cmr_username`, and `cmr_password`: These values must be
  set correctly for publishing metadata to the CMR.  Consult with a team
  member for correct values, if and when you want to publish to the CMR.

## Deployment

To ensure `terraform` sees the environment variable values provided in your
`.env` file, each `*-tf` module directory includes a `tf` script to minimize
typing effort.  The `tf` script is just a simple wrapper that invokes
`terraform` with the same arguments supplied to the `tf` script, but takes care
of setting the variables defined in the `.env` file.

### Deploy the `rds-cluster` Module

To deploy the `rds-cluster` module, which must be deployed at least once
prior to the first time the cumulus module is deployed (see below), do the
following:

1. Change directory to `rds-cluster-tf`
1. Run `./tf init -reconfigure`
1. Run `./tf apply` (initially, this might take roughly 5-10 minutes to complete)

You should generally not have to deploy this module again, except perhaps during
a Cumulus upgrade.

### Deploy the `data-persistence` Module

To deploy the `data-persistence` module, which must be deployed at least once
prior to the first time the cumulus module is deployed (see below), do the
following:

1. Change directory to `data-persistence-tf`
1. Run `./tf init -reconfigure`
1. Run `./tf apply` (initially, this might take roughly 40 minutes to complete)

You should generally not have to deploy this module again, except perhaps during
a Cumulus upgrade.

### Deploy the `cumulus` Module

As noted above, the `cumulus` module depends on the `data-persistence` module,
so the `data-persistence` module must be deployed at least once prior to
deploying the `cumulus` module.  To deploy the `cumulus` module:

1. Change directory to `cumulus-tf`
1. Run `./tf init -reconfigure`
1. Run `./tf apply` (initially, this might take roughly 1 hour to complete).
   Note that at roughly the 1-hour mark, the command might fail with several
   error messages of the following form:

   ```plain
   Error: error creating Lambda Function (1): InvalidParameterValueException: The provided execution role does not have permissions to call CreateNetworkInterface on EC2
   {
      RespMetadata: {
         StatusCode: 400,
         RequestID: "2215b3d5-9df6-4b27-8b3b-57d76a64a4cc"
      },
      Message_: "The provided execution role does not have permissions to call CreateNetworkInterface on EC2",
      Type: "User"
   }
   ```

   If this occurs, simply run `./tf apply` again.  See
   [Deploying Cumulus Troubleshooting] for more information.

Finally, if you registered an Earthdata Login application to obtain values for
your `urs_client_id` and `urs_client_password` variables, as mentioned above,
then you must [update your Earthdata application] **only after your initial
deployment** of the `cumulus` module.  If you don't do so after your initial
deployment, you can do so later by running the following command to obtain the
required values:

```plain
./tf output
```

### Destroying a Deployment

**DANGER:** This should be used only in the event that you need to completely
destroy a deployment, _including all related data_.  Typically, this should be
used only when removing a development deployment, particularly when a team
member leaves the team:

```plan
./destroy-all.sh
```

To prevent accidental annihilation, **the script will prompt you for explicit
confirmation** of your intention.  If you provide explicit confirmation at the
prompt, it performs what is described in the Cumulus documentation under
[How to Destroy Everything].

[Deploying Cumulus Troubleshooting]:
   https://nasa.github.io/cumulus/docs/troubleshooting/troubleshooting-deployment#deploying-cumulus
[How to Destroy Everything]:
   https://nasa.github.io/cumulus/docs/v9.0.0/deployment/terraform-best-practices#how-to-destroy-everything
[Install tfenv]:
   https://github.com/tfutils/tfenv
[Install AWS CLI v2]:
   https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
[NGAP cloudtamer.io portal]:
   https://cloud.earthdata.nasa.gov
[register an Earthdata Login application]:
   https://nasa.github.io/cumulus/docs/deployment/deployment-readme#configure-earthdata-application
[update your Earthdata application]:
   https://nasa.github.io/cumulus/docs/v9.0.0/deployment/deployment-readme#update-earthdata-application
