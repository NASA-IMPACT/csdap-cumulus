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
  named `.env` (also placing it at the root of this project), if it does not
  already exist.

  Using a text editor, set values within your `.env` file according to the
  instructions provided within the file.  These environment variables will be
  used within the Docker container to properly configure the AWS CLI and
  Terraform.

## Deploying Cumulus

This section assumes that you have completed all prerequisite steps as detailed
above.

To deploy Cumulus, all the necessary tools and dependencies are bundled within a
Docker image.  To build the image, run the following:

```plain
make docker
```

Once the image is built (which you shouldn't have to do again unless the
`Dockerfile` is changed), deploy Cumulus with the following command:

```plain
make deploy
```

This will deploy all out-of-date modules in the correct order dictated by their
dependencies specified in the `Makefile`.

Upon initial deployment, all modules will be deployed, which should take roughly
2 hours in total.  Note that close to the end of the process, deployment might
fail with several error messages of the following form:

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

If this occurs, simply run the previous command again.  See
[Deploying Cumulus Troubleshooting] for more information.

### Destroying a Deployment

**DANGER:** This should be used only in the event that you need to completely
destroy a deployment, _including all related data_.  Typically, this should be
used only when removing a development deployment, particularly when a team
member leaves the team:

```plan
make destroy
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
   https://nasa.github.io/cumulus/docs/v9.0.0/deployment/terraform-best-practices#how-to-destroy-everything
[Register an Earthdata Login Application]:
   https://wiki.earthdata.nasa.gov/display/EL/How+To+Register+An+Application
[Update Your Earthdata Application]:
   https://nasa.github.io/cumulus/docs/v9.0.0/deployment/deployment-readme#update-earthdata-application
