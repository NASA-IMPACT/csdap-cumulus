# Troubleshooting

- [Deployment](#deployment)
  - [Execution Role Does Not Have Permissions](#execution-role-does-not-have-permissions)
  - [Duplicate Resources](#duplicate-resources)
- [Destroying a Deployment](#destroying-a-deployment)
  - [Error Reading Secrets Manager Secret Policy](#error-reading-secrets-manager-secret-policy)
  - [Instance Cannot be Destroyed (Resource has `lifecycle.prevent_destroy` set)](#instance-cannot-be-destroyed-resource-has-lifecycleprevent_destroy-set)
  - [Error Deleting Lambda ENIs Using Security Group](#error-deleting-lambda-enis-using-security-group)
  - [Error Deleting EventBridge Rule](#error-deleting-eventbridge-rule)
  - [Error Deleting Security Group (DependencyViolation)](#error-deleting-security-group-dependencyviolation)
  - [Error Deleting RDS Cluster (Cannot delete protected Cluster)](#error-deleting-rds-cluster-cannot-delete-protected-cluster)

## Deployment

### Execution Role Does Not Have Permissions

During deployment, you may encounter a number of permissions errors of the form:

```plain
The provided execution role does not have permissions to call ACTION on SERVICE
```

This is generally due to either a failure to identify a dependency between
resources or some race condition between them, as Terraform often creates
several resources in parallel.  Where there are clear dependencies between
resources, Terraform will serialize their creation, as appropriate, but
sometimes a dependency is not identified, or creation of an
eventually-consistent dependency is not yet consistent, and thus you might see
errors of the form above.

The fix for this problem is simple: **Rerun your deployment command**, and by
the time Terraform again attempts to perform the previously failing operation,
it will succeed.  If it fails again, rerun the deployment again, until you no
longer see such permissions errors.

### Duplicate Resources

Spotty network connectivity can be a major problem during deployment when the
Terraform state file is saved remotely (in an S3 bucket in our case).  The issue
is that when Terraform makes a request for AWS to create (or update) a resource
(or even several in parallel), and the network connection between AWS and the
machine on which Terraform is running is dropped, Terraform can lose track of
the state of the in-flight resource requests.

Attempting to deploy again, once network connectivity is restored, can result in
a number of "duplicate resource" errors, such as the following (this is not
exhaustive):

- `Error: error creating Security Group (<SG-NAME>): InvalidGroup.Duplicate`
- `Error: Creating CloudWatch Log Group failed: ResourceAlreadyExistsException`
- `Error: failed creating IAM Role (<ID>): EntityAlreadyExists`
- `Error: error creating SSM parameter (<ID>): ParameterAlreadyExists`
- `Error: error creating DynamoDB Table: ResourceInUseException: Table already exists`

In most cases, the best thing to do is to "import" the resource into Terraform,
which effectively means letting Terraform know that the resource was already
created, and that there is no need to attempt to create it again.

However, determining the correct arguments to provide to the `terraform import`
command is not easy, and if you have to import many resources, attempting to
manually import all of them can be downright tedious, error-prone, and
time-consuming.

Therefore, you can use the Terraform Doctor script to automatically address
most, if not all, of these errors for you.  Although not required, the easiest
way to make use of Terraform Doctor is after running `make all-up` (or
`make all-up-yes`) because that command will write all errors to log files
(whereas using `make up-MODULE` for a particular module will not write to log
files).

After `make all-up` (or `make all-up-yes`) fails with various "duplicate
resource" errors, run Terraform Doctor for the particular module for which the
errors occurred, where `MODULE` is `cumulus`, `data-persistence`, or
`rds-cluster`:

```sh
make terraform-doctor-MODULE
```

If there are several "duplicate resource" errors, this may take a bit of time,
as each `terraform import` command can import only one resource at a time, and
each time it must lock the state file, import the resource, and release the
lock.

## Destroying a Deployment

### Error Reading Secrets Manager Secret Policy

If you encounter the following error, it sadly does not indicate the name of the
secret in error:

```plain
Error: error reading Secrets Manager Secret policy: InvalidRequestException: You
can't perform this operation on the secret because it was marked for deletion.
```

The way to resolve this is to locate the secrets that are marked for deletion,
and cancel their deletion.  Unfortunately, there is no way (at this time) to use
the AWS CLI to list secrets that are marked for deletion, so this must be done
via the AWS Console as follows:

1. Navigate to Secrets Manager and find the list of secrets
1. By default, secrets marked for deletion are _not_ listed.  Therefore, on the
   secrets list page, click the gear icon near the upper right corner of the
   list (under the "Store a new secret" button) to open a dialog box.
1. On the left side of the dialog box, check the box next to **Show secrets
   scheduled for deletion**
1. Click **Save**

At this point, the list of secrets should include the secrets marked for
deletion, but does not indicate (within the list) which ones they are.  You must
now click on each secret to see if it is marked for deletion.  If it is, there
will be a **Cancel deletion** button in the upper right corner of the details
page for the secret.  Click the button, then return to the list and click
through to the detail page for every secret, clicking the **Cancel deletion**
button for every secret that shows it.

Once all scheduled deletions are cancelled, you should be able to resume your
destruction.

### Instance Cannot be Destroyed (Resource has `lifecycle.prevent_destroy` set)

During destruction of the `data-persistence` module, you will encounter the
following error for every DynamoDB table in the deployment:

```plain
Error: Instance cannot be destroyed

  on .terraform/modules/data_persistence/tf-modules/data-persistence/dynamo.tf line 18:
  18: resource "aws_dynamodb_table" "access_tokens_table" {

Resource module.data_persistence.aws_dynamodb_table.access_tokens_table has
lifecycle.prevent_destroy set, but the plan calls for this resource to be
destroyed. To avoid this error and continue with the plan, either disable
lifecycle.prevent_destroy or reduce the scope of the plan using the -target
flag.
```

This is because the Cumulus Terraform configuration prevents automatic
destruction of these tables, specifically to add a safety net to reduce the
chance of accidentally deleting the wrong tables, or deleting the tables before
they are backed up.

Once the destruction fails with messages similar to the one above, double-check
that you are indeed attempting to destroy the correct deployment by checking the
list of tables that you will delete:

```sh
aws dynamodb list-tables --query '*' --output text |
  tr '\t' '\n' |
  grep "${CUMULUS_PREFIX}-.*Table"
```

If the list of tables looks correct, if necessary, back them up. Once you're
ready, run the following command to delete them:

```sh
# CAUTION: THIS WILL DELETE ALL OF YOUR DYNAMODB TABLES!
aws dynamodb list-tables --query '*' --output text |
  tr '\t' '\n' |
  grep "${CUMULUS_PREFIX}-.*Table" |
  xargs -L1 aws dynamodb delete-table --table-name
```

### Error Deleting Lambda ENIs Using Security Group

At some point during destruction of your deployment, you may see an error
similar to the following. However, this will likely happen only when attempting
to destroy a particular module before destroying a dependent module, such as
when attempting to destroy the `data-persistence` module without having already
destroyed the `cumulus` module:

```plain
... snip ...
module.data_persistence.aws_security_group.es_vpc[0]: Still destroying...
[id=sg-00d7d0b93f7d1bd18, 44m51s elapsed] Releasing state lock. This may take a
few moments...

Error: error deleting Lambda ENIs using Security Group (sg-00d7d0b93f7d1bd18):
error waiting for Lambda ENI (eni-04c56524060f32821) to become available for
detachment: timeout while waiting for state to become 'available' (last state:
'in-use', timeout: 45m0s)
```

The reasons for this are beyond the scope of this troubleshooting section, but
such an error requires you to [find ENI associations]. The Docker image for
this repository already has the necessary support tools installed for finding
your ENI associations, so you can simply run the following command to do so,
where `<ENI>` is the ID of the Lambda ENI given in the error message above:

```sh
findEniAssociations --region ${AWS_REGION} --eni <ENI>
```

You should see output similar to the following:

```plain
This script is for determining why an ENI that is managed by AWS Lambda has not
been deleted.

Found eni-04c56524060f32821 with subnet-0e14d8999b039d927 using Security Groups
sg-00d7d0b93f7d1bd18 sg-0b13e2c1c708f3a8b
Searching for Lambda function versions using subnet-0e14d8999b039d927 and
Security Groups sg-00d7d0b93f7d1bd18 sg-0b13e2c1c708f3a8b...

The following function version(s) use the same subnet and security groups as
eni-04c56524060f32821. They will need to be disassociated/deleted before Lambda
will clean up this ENI:
arn:aws:lambda:us-west-2:852078737469:function:cumulus-chuckwondo-executeMigrations:$LATEST
arn:aws:lambda:us-west-2:852078737469:function:cumulus-chuckwondo-dbIndexer:$LATEST
arn:aws:lambda:us-west-2:852078737469:function:cumulus-chuckwondo-CustomBootstrap:$LATEST
arn:aws:lambda:us-west-2:852078737469:function:cumulus-chuckwondo-CreateReconciliationReport:$LATEST
arn:aws:lambda:us-west-2:852078737469:function:cumulus-chuckwondo-IndexFromDatabase:$LATEST
```

What you need to do is delete each of the listed Lambda functions, by running
the following command for each, where `<NAME>` is the name of the Lambda function,
which appears between `function:` and `:$LATEST` (e.g.,
`cumulus-chuckwondo-IndexFromDatabase`):

```sh
aws lambda delete-function --function-name <NAME>
```

If there are several lambda functions, you can save yourself some effort by
using the following command to find them and delete them all at once:

```sh
aws-support-tools/Lambda/FindEniMappings/findEniAssociations \
  --region ${AWS_REGION} \
  --eni <ENI> | grep ':function:' | xargs -L1 aws lambda delete-function --function-name
```

Once you've deleted the Lambda functions, run the `findEniAssociations` command
again to make sure you've deleted them all.

Your destruction command might fail again for the same reason, but for a
different ENI.  If so, repeat the steps above, using the new ENI given in the
new error message.

### Error Deleting EventBridge Rule

When attempting to delete an EventBridge Rule that still has targets, you'll see
an error like so:

```plain
Error: error deleting EventBridge Rule (<NAME>): ValidationException: Rule can't
be deleted since it has targets.
```

You must first find the IDs of the attached targets:

```sh
aws events list-targets-by-rule --query Targets[].Id --output text --rule <NAME>
```

Then, remove the targest by running the following, where `<IDS>` is the output
from the preceding command:

```sh
aws events remove-targets --rule <NAME> --ids <IDS>
```

Destruction should now be able to delete the EventBridge Rule.

### Error Deleting Security Group (DependencyViolation)

Another possible error you will encounter, due to resource dependencies, is the
following. However, this will likely happen only when attempting to destroy a
particular module before destroying a dependent module, such as when attempting
to destroy the `data-persistence` module without having already destroyed the
`cumulus` module:

```plain
... snip ...
module.data_persistence.aws_security_group.es_vpc[0]: Still destroying...
[id=sg-00d7d0b93f7d1bd18, 25m20s elapsed]
Releasing state lock. This may take a few moments...

Error: Error deleting security group: DependencyViolation: resource
sg-00d7d0b93f7d1bd18 has a dependent object
        status code: 400, request id: 6f6a8336-0c73-436b-85e4-bf1f41706529
```

This is another error related to ENIs, but the solution for this type of error
is different than that described in the previous section.

The first thing to do is find the ENI associated with the security group, by
running the following, where `<ID>` is the Security Group ID specified in the
error message above (e.g., `sg-00d7d0b93f7d1bd18`):

```sh
aws ec2 describe-network-interfaces --query \
  "NetworkInterfaces[?Groups[?GroupId == '<ID>']].{ENI: NetworkInterfaceId, Groups: Groups}"
```

You should see output similar to the following:

```json
[
    "ENI": "eni-01fc3b34ab4564f46",
    "Groups": [
        {
            "GroupName": "terraform-20210607154201465900000001",
            "GroupId": "sg-00d7d0b93f7d1bd18"
        },
        {
            "GroupName": "cumulus_rds_cluster_acess_ingress20210607202303912100000005",
            "GroupId": "sg-054b944da6baa22f3"
        },
        {
            "GroupName": "terraform-20210607172222332900000005",
            "GroupId": "sg-08c5c672d6ff9978d"
        }
    ]
]
```

Notice that in this case, there are 2 other security groups (aside from the one
mentioned in the error message) associated with the ENI. We must drop the
security group mentioned in the error message by simply updating the ENI's
`groups` attribute to consist of only the _other_ security groups, where `<ENI>`
is the `ENI` value from above, and `<ID1>` and `<ID2>` are the _other_ security
group IDs, also from above:

```sh
aws ec2 modify-network-interface-attribute \
  --network-interface-id <ENI> \
  --groups <ID1> <ID2>
```

Confirm you have correctly modified the ENI attribute, where `<ENI>` is the ENI
from above:

```sh
aws ec2 describe-network-interface-attribute \
  --network-interface-id <ENI> \
  --attribute groupSet
```

You should now see that the problematic security group is no longer listed:

```json
{
    "Groups": [
        {
            "GroupName": "cumulus_rds_cluster_acess_ingress20210607202303912100000005",
            "GroupId": "sg-054b944da6baa22f3"
        },
        {
            "GroupName": "terraform-20210607172222332900000005",
            "GroupId": "sg-08c5c672d6ff9978d"
        }
    ],
    "NetworkInterfaceId": "eni-01fc3b34ab4564f46"
}
```

### Error Deleting RDS Cluster (Cannot delete protected Cluster)

During destruction of the `rds-cluster` module, you will run into an error like
the following:

```plain
Error: error deleting RDS Cluster (cumulus-chuckwondo-rds-serverless):
InvalidParameterCombination: Cannot delete protected Cluster, please disable
deletion protection and try again.
        status code: 400, request id: 46c3da8c-7abd-4c6f-b552-0cf2d26da261
```

To resolve this, you must first remove deletion protection from the RDS cluster,
where `<ID>` is the RDS cluster ID shown in parentheses in the error message
above (e.g., `cumulus-chuckwondo-rds-serverless`, _not_ the request ID):

```sh
aws rds modify-db-cluster --no-deletion-protection --db-cluster-identifier <ID>
```

You should then be able to delete the cluster:

```sh
aws rds delete-db-cluster --skip-final-snapshot --db-cluster-identifier <ID>
```

At this point, you should be able to rerun destruction of the `rds-cluster`
module.

[Find ENI Associations]:
  https://aws.amazon.com/premiumsupport/knowledge-center/lambda-eni-find-delete/