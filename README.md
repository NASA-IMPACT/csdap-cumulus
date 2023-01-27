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

Further, it is good practice to run the command above whenever you switch
branches, or pull the latest code on any branch, in case changes were made to
any files that affect the Docker image.

### Deploying Cumulus

Once the Docker image is built, perform some setup required prior to your first
deployment of Cumulus:

```plain
make pre-deploy-setup
```

Next, deploy all of the Terraform modules with the following command, which
will deploy the modules in the correct order of their dependencies:

```plain
make all-up-yes
```

The first time you run the `make all-up-yes` command, you will be prompted to
supply values for a number of secrets, which will be stored as AWS SSM
Parameters of type SecureString.

If you are unsure of what value to supply for a prompt, consult a team member
who has already deployed Cumulus from this repository.  If you cannot
immediately obtain an appropriate value for a prompt, you may simply supply an
empty value (i.e., simply press Enter/Return).  This will allow you to continue
with deployment, and add the secret value at a later point.  The next time you
deploy Cumulus, you will be reprompted for any values that you have not yet
supplied.

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

After your initial, successful deployment, one of the listed deployment outputs
will be `cumulus_distribution_api_uri`.  To locate this output, look at the file
`log/up/cumulus.log`.  The output should appear near the end of the file, and
the line should look similar to the following:

```plain
[... terraspace up cumulus]: cumulus_distribution_api_uri = <URI>
```

Add the following line to your `.env` file, where `<URI>` is the value of that
output.  Note that if you copied your `.env` file from `.env.example`, you
should already have a line at the bottom of the file that you can uncomment and
paste the value of `<URI>` there:

```plain
TF_VAR_cumulus_distribution_url=<URI>
```

Then, to apply the value, redploy the `cumulus` module, as follows:

```plain
make up-cumulus-yes
```

Finally, populate your development deployment with some data that will allow you
to perform a small smoke test to verify that your deployment is operating
properly:

```plain
make create-test-data
```

To run a smoke test, follow the instructions output by the command above.

### Destroying a Deployment

See [Destroying a Deployment](docs/OPERATING.md#destroying-a-deployment) in
[Operating CSDAP Cumulus](docs/OPERATING.md).

[Deploying Cumulus Troubleshooting]:
   https://nasa.github.io/cumulus/docs/troubleshooting/troubleshooting-deployment#deploying-cumulus
[Terraform]:
   https://www.terraform.io/
[Terraspace]:
   https://terraspace.cloud/
