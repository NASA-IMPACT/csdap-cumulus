# CSDAP Cumulus

The purpose of CSDAP Cumulus is to ingest granule data (previously obtained from
vendors, such as Planet and Maxar) into the Earthdata Cloud. In conjunction with
such ingestion, granule metadata (in UMM-G format) is published to the NASA CMR
(Content Metadata Repository) for discovery.

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
SecureString.

If you are unsure of what value to supply for a prompt, consult
a team member who has already deployed Cumulus from this repository.  If you
cannot immediately obtain an appropriate value for a prompt, you may simply
supply a dummy value (e.g., TBD).  This will allow you to continue with deployment,
and add the secret value at a later point, but you'll have to use the AWS CLI or
AWS Management Console to do so, because during subsequent deployments, you will
no longer be prompted for the value.

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

One of the outputs from your deployment will be `cumulus_distribution_api_uri`.
Copy the value to `.env` for `TF_VAR_cumulus_distribution_url`. Then redeploy.

### Destroying a Deployment

See [Destroying a Deployment](docs/OPERATING.md#destroying-a-deployment) in
[Operating CSDAP Cumulus](docs/OPERATING.md)

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
1. Switch to your terminal window and run `make output-cumulus` to show the
   Terraform outputs for your Cumulus deployment.
1. Copy the value of `archive_api_redirect_uri`, go back to your Earthdata Login
   browser session, paste the value into the text box for
   **Redirect Uri to add**, and click the **ADD REDIRECT URI** button.
1. Repeat the previous step for the value of `cumulus_distribution_api_redirect_uri`.

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
1. Run `make up-cumulus` to redeploy your
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
