# CSDAP Cumulus

## Prerequisites

The following steps are **required** prerequisites for deploying Cumulus using
this repository:

- **Install Docker Engine**

  Follow the steps appropriate for your operating system to
  [install Docker Engine](https://docs.docker.com/engine/install/).

  To simplify setup and deployment of Cumulus, this project uses a Docker
  container with the necessary tools already installed, including the AWS CLI
  (since Cumulus will be deployed to AWS) and Terraform (since Cumulus AWS
  resources are deployed via Terraform).

- **Populate Environment Variables**

  Copy the file named `.env.example` (at the root of this project) to a file
  named `.env` (also placing it at the root of this project).

  Using a text editor, set values within your `.env` file according to the
  instructions provided within the file.  These environment variables will be
  used within the Docker container to properly configure the AWS CLI and
  Terraform.

## Infrastructure Management

This section assumes that you have completed all prerequisite steps as detailed
above.

Cumulus uses [Terraform] to manage AWS infrastructure.  However, because using
Terraform directly is somewhat cumbersome, we leverage [Terraspace] to make use
of Terraform a bit easier.  In addition, we use Docker to simplify local
development and deployment.

### Docker for Development

To avoid having to install Terraform, Terraspace, and other tools locally, we
use a Docker container to package all of our tooling requirements.  Therefore,
before you can deploy Cumulus, you must first build the Docker image, as
follows:

```plain
make docker
```

Once the image is built, you should not have to build it again unless one of the
following files change:

- `.dockerignore`
- `.terraform-version`
- `Dockerfile`
- `Gemfile`
- `Gemfile.lock`

### Deploying Cumulus

Once the Docker image is built, deploy all of the Terraform modules with the
following command, which will deploy the modules in the correct order of their
dependencies:

```plain
make all-up
```

The first time you run this command, you will be prompted to supply values for a
number of secrets, which will be stored as AWS SSM Parameters of type
SecureString.  If you are unsure what values to supply for the prompts, consult
a team member who has already deployed Cumulus from this repository.

Subsequent deployments will use the secret values supplied during your initial
deployment, so if you need to change any of the parameters, you must do so
manually via the AWS CLI or AWS Management Console.

Initial deployment will take roughly 2 hours in total, but close to the end of
the process, the deployment might fail with several error messages of the
following form:

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

If this occurs, simply run the previous command again, as this typically arises
from a race condition where one resource depends upon another resource that is
not yet fully ready.  Typically, by the time you rerun the command, the required
resource is ready.  See [Deploying Cumulus Troubleshooting] for more
information.

After your initial, successful, full deployment, you should rarely need to
redeploy _all_ of the modules that Cumulus comprises.  Therefore, you may
perform subsequent deployments with the following command:

```plain
make up-cumulus
```

Since this will avoid deploying the other modules, deployment time will be
shorter.

### Destroying a Deployment

**DANGER:** This should be used only in the event that you need to completely
destroy a deployment, _including all related data_.  Typically, this should be
used only when removing a development deployment, particularly when a team
member leaves the team:

```plan
# TBD
```

To prevent accidental annihilation, **the script will prompt you for explicit
confirmation** of your intention.  If you provide explicit confirmation at the
prompt, it performs what is described in the Cumulus documentation under
[How to Destroy Everything].

## Using the Cumulus Dashboard

If you wish to use the Cumulus Dashboard with your Cumulus deployment, follow
the steps in this section.  Otherwise, you may skip these instructions.

### Registering and Configuring an Earthdata Login Application

Since the Cumulus Dashboard uses the Cumulus API (deployed as part of Cumulus),
and the Cumulus API uses Earthdata Login for authentication, you must
[register an Earthdata Login application] in order to enable such
authentication.  Since the registration process can take several days to
complete, it is recommended that you initiate the appropriate request as soon as
possible.

Once you receive notification that your application registration is complete,
and you have also successfully deployed Cumulus as described above, you must
update your Earthdata application as follows:

1. Login to [Earthdata Login]
1. Navigate to **Applications > My Applications**
1. To the right of your listed Cumulus application, click either the Home or
   Edit icon to show the details of your application.
1. Along the top of the page, there are navigation links.  Click
   **Manage > Redirect Uris**.
1. Switch to your terminal window in your Docker container (if necessary, run
   `make docker`)
1. Within your Docker container, run `make cumulus-tf/output` to show the
   Terraform outputs for your Cumulus deployment.
1. Copy the value of `archive_api_redirect_uri`, go back to your Earthdata Login
   browser session, paste the value into the text box for
   **Redirect Uri to add**, and click the **ADD REDIRECT URI** button.
1. Repeat the previous step for the value of `distribution_redirect_uri`.

Finally, you must set appropriate values for related environment variables in
your `.env` file, as follows:

1. Still within your EDL session, click the **Details** link in the row of links
   along the top of the page.
1. Copy the value of **Client ID** and paste it as the value of the
   `URS_CLIENT_ID` variable in your `.env` file.
1. Click **Manage > App Password** in the row of links along the top.
1. Click **RESET PASSWORD** to initiate the process of setting an application
   password.
1. Once you have obtained an application password, set the value of the
   `URS_CLIENT_PASSWORD` variable in your `.env` file to your application
   password.
1. Add your EDL username (in double quotes) to the list of `API_USERS` in your
   `.env` file.
1. Save your `.env` file.
1. From your Docker container, run `make cumulus-tf/deploy` to redeploy your
   `cumulus` module so that your Cumulus API can perform authentication against
   your EDL application.

### Deploying and Launching the Cumulus Dashboard

TBD

[Deploying Cumulus Troubleshooting]:
   https://nasa.github.io/cumulus/docs/troubleshooting/troubleshooting-deployment#deploying-cumulus
[Earthdata Login]:
   https://uat.urs.earthdata.nasa.gov/
[How to Destroy Everything]:
   https://nasa.github.io/cumulus/docs/deployment/terraform-best-practices#how-to-destroy-everything
[Register an Earthdata Login Application]:
   https://wiki.earthdata.nasa.gov/display/EL/How+To+Register+An+Application
[Terraform]:
   https://www.terraform.io/
[Terraspace]:
   https://terraspace.cloud/
[Update Your Earthdata Application]:
   https://nasa.github.io/cumulus/docs/deployment/deployment-readme#update-earthdata-application
