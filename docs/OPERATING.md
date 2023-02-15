# Operating CSDAP Cumulus

- [The Cumulus CLI](#the-cumulus-cli)
  - [Running Commands](#running-commands)
  - [Running Against Non-Development Deployments](#running-against-non-development-deployments)
- [Defining Cumulus Data Management Items](#defining-cumulus-data-management-items)
  - [Supporting a New Collection](#supporting-a-new-collection)
  - [Defining a Provider](#defining-a-provider)
  - [Defining a Collection](#defining-a-collection)
  - [Defining a Rule](#defining-a-rule)
- [Ingesting a Collection](#ingesting-a-collection)
  - [Triggering Discovery and Ingestion](#triggering-discovery-and-ingestion)
  - [Viewing CloudWatch Logs](#viewing-cloudwatch-logs)
  - [Performing Discovery without Ingestion](#performing-discovery-without-ingestion)
- [Destroying a Deployment](#destroying-a-deployment)
  - [Destroying Managed Resources](#destroying-managed-resources)
  - [Destroying Unmanaged Resources](#destroying-unmanaged-resources)
- [Appendix](#appendix)
  - [Skip Granule Discovery for Disabled Rules](#skip-granule-discovery-for-disabled-rules)

## The Cumulus CLI

The [Cumulus CLI] is a command-line interface for performing various Cumulus
operational tasks.  It simply makes calls to the [Cumulus API] from the
command-line, rather than via the Cumulus Dashboard, which is particularly
useful when the Dashboard is not deployed, or there is a need to script tasks.

However, the CLI does not provide complete coverage of the Cumulus API, nor does
it provide as much functionality as the Dashboard. Rather, it is focused on
supporting a small number of common operational functions, such as managing
providers, collections, and rules (see [Cumulus Data Management Types]).

### Running Commands

The Docker development image, which you should have already built, includes the
Cumulus CLI, so there's no need to manually install it, but the Cumulus CLI is
used throughout the instructions in this document.  If you have not already
built the Docker image, do so by running the following command at the root of
this project:

```plain
make docker
```

In the following sections of this guide, when instructed to run a Cumulus CLI
command, you should do so from within the Docker container, by first starting a
`bash` session within the container as follows:

```sh
make bash
```

Where instructions indicate that you should use the Cumulus CLI, complete
commands are given, but if you wish to see the available commands,  run the following:

```sh
cumulus --help
```

If you wish to see more details about a command's available options, run the
following:

```sh
cumulus <command> --help
```

### Running Against Non-Development Deployments

By default, when you use `make bash` to open a bash session within the Docker
container, the following environment variables are automatically set within the
container:

- `AWS_REGION` (from `.env`)
- `AWS_PROFILE` (from `.env`)
- `TS_ENV` (from `.env`)
- `CUMULUS_PREFIX` (automatically set to `"cumulus-${TS_ENV}"`)

Since the Cumulus CLI makes calls to AWS services, it requires `AWS_REGION` and
`AWS_PROFILE` to be set.  Further, it requires `CUMULUS_PREFIX` to be set in
order to use the correct AWS resources created via Terraform.  Since these
values should be set as appropriate for your "development" Cumulus stack, by
default, the Cumulus CLI will operate against that stack.

Therefore, in order to manage items in the database for the Cumulus UAT, SIT, or
Production deployments, you must override these values as necessary when running
`cumulus` commands.  Since all of our deployments are in the same AWS region,
there should be no need to override `AWS_REGION`, and since our "development"
deployments are in the UAT account, there is no need to override `AWS_PROFILE`
to apply changes to the UAT deployment.

Here are the command-line changes required for querying or changing
non-development Cumulus stacks, where `<PROFILE>` is the name of the appropriate
AWS profile that you have created for either SIT or Prod:

| Environment | Command
|:------------|:-------
|**"dev"**    | `cumulus <command> <args>`
|**UAT**      | `cumulus --prefix cumulus-uat <command> <args>`
|**SIT**      | `AWS_PROFILE=<PROFILE> cumulus --prefix cumulus-sit <command> <args>`
|**Prod**     | `AWS_PROFILE=<PROFILE> cumulus --prefix cumulus-prod <command> <args>`

Note that the `--prefix` option is used in the commands above, rather than
setting the `CUMULUS_PREFIX` environment variable.

## Defining Cumulus Data Management Items

### Supporting a New Collection

Before granules in a collection can be discovered and ingested, it is necessary
to first define the following Cumulus Data Management items:

1. A [provider], which simply specifies _where_ to look in order to "discover"
   granule files.  This is where files will be copied _from_.  For this project,
   this is always an S3 bucket (i.e., the `protocol` property is `s3`).  Note
   that a given provider may be the source for more than one collection.
1. A [collection], which describes various details about a collection.  In
   addition to its name and version, it also includes information about where to
   specifically locate the collection's files (relative to the source specified
   by the _provider_), and how to extract the Granule ID (UR) from each filename
   in a list of "discovered" files for the collection, among other things.
1. A [rule] for triggering the workflow (AWS StepFunction) to discover granules
   of a specified _collection_ from a specified _provider_.  For this project,
   the workflow is always `DiscoverAndQueueGranules`.

All of these items must be described using JSON in order to populate the Cumulus
database with them.  As such, the convention used in this project is to version
these items in `.json` files rooted at `app/stacks/cumulus/resources/<TYPE>`,
where `<TYPE>` is one of `providers`, `collections`, or `rules` (note that they
are all plural forms).

In addition, there are some test fixture files for granules under
`app/stacks/cumulus/resources/granules`, which are only dummy files for running
smoke tests, other than the `*cmr.json` files, which are valid UMM-G files in
order to allow smoke tests to succeed during the step that publishes CMR
metadata to the UAT CMR.

The following sections describe how to manage these items.

### Defining a Provider

The first step required in order to be able to discover granules in a collection
is to define a [provider] in a `.json` file under
`app/stacks/cumulus/resources/providers`, naming the file the same as the
provider's `"id"` property.

In this project, we're only discovering granules in AWS S3 buckets, so this
means that to define a provider, we must create the file
`app/stacks/cumulus/resources/providers/<PROVIDER_ID>.json` with the following
contents (with the convention that `<PROVIDER_ID>` is all lowercase, both for
the filename as well as for the value of `"id"` within the file):

```json
{
  "id": "<PROVIDER_ID>",
  "protocol": "s3",
  "host": "<BUCKET_NAME>"
}
```

Note that all provider definitions are required to specify an `"id"`,
`"protocol"`, and `"host"`, and that when the `"protocol"` is `"s3"`, the
`"host"` is the **name of the AWS S3 Bucket where granule files will be
discovered**.

Further, the S3 bucket policy must include the following policy statement in
order for the UAT, SIT, and Prod accounts to be able to discover and ingest
files from the bucket.  The owner of the account containing the bucket must
apply the policy change:

```json
{
  "Effect": "Allow",
  "Principal": {
    "AWS": [
      "arn:aws:iam::<UAT_ACCOUNT_ID>:role/cumulus-uat-lambda-processing",
      "arn:aws:iam::<UAT_ACCOUNT_ID>:role/cumulus-uat_ecs_cluster_instance_role",
      "arn:aws:iam::<SIT_ACCOUNT_ID>:role/cumulus-sit-lambda-processing",
      "arn:aws:iam::<SIT_ACCOUNT_ID>:role/cumulus-sit_ecs_cluster_instance_role",
      "arn:aws:iam::<PROD_ACCOUNT_ID>:role/cumulus-prod-lambda-processing",
      "arn:aws:iam::<PROD_ACCOUNT_ID>:role/cumulus-prod_ecs_cluster_instance_role"
    ]
  },
  "Action": [
    "s3:GetObject",
    "s3:GetObjectTagging",
    "s3:GetObjectVersionTagging",
    "s3:ListBucket"
  ],
  "Resource": [
    "arn:aws:s3:::<BUCKET_NAME>/*",
    "arn:aws:s3:::<BUCKET_NAME>"
  ]
}
```

The `UAT_ACCOUNT_ID`, `SIT_ACCOUNT_ID` and `PROD_ACCOUNT_ID` are the account IDs
for the following AWS accounts, respectively, but the account IDs are _not_
specified in this document, as a security measure.  You must login to the each
account in order to obtain the account ID and supply the IDs to the owner of any
bucket to which you wish to apply the above policy:

- `csdap-cumulus-uat-7469`
- `csdap-cumulus-prod-5982`
- `csda-cumulus-uat-1686` (CBA)
- `csda-cumulus-prod-5047` (CBA)

If the permissions are not specified, then attempting to discover and ingest a
collection from the provider will fail with an appropriate "access denied"
error, which should appear in the logs for the `DiscoverGranules` ECS task.

Once a provider `.json` file is created, you can add it to the Cumulus database
(or update it) with the following command (from within the Docker container):

```sh
cumulus providers upsert --data \
  app/stacks/cumulus/resources/providers/<PROVIDER_ID>.json
```

Also note that a provider may store granule files for **multiple** collections,
so the provider definition alone does not specify all of the information we need
for "discovery."  Only when a providier is used in combination with a collection
and a rule can we perform discovery and ingestion of granules for a particular
collection.  The following section covers defining a collection.

**REMINDER:** To run `cumulus` commands against a non-development Cumulus
deployment, see
[Running Against Non-Development Deployments](#running-against-non-development-deployments).

In addition to creating a new provider definition, you must also add the
provider's bucket to the list of buckets configured in Terraform, if the bucket
is not already configured.  This requires adding the bucket definition to
`app/stacks/cumulus/tfvars/base.tfvars`, **within the existing `buckets`
variable**, in the section at the bottom for **non-sandbox provider buckets**:

```hcl
<PROVIDER_ID> = {
  name = "<BUCKET_NAME>"
  type = "provider"
}
```

where `<PROVIDER_ID>` and `<BUCKET_NAME>` are the same values you used within
the corresponding provider's `.json` file definition, as described earlier.

**IMPORTANT:** Note that there are _no_ quotes surrounding `<PROVIDER_ID>`, but
that there _are_ quotes surrounding `<BUCKET_NAME>`.

**IMPORTANT:** When you add a new bucket definition, **you must redeploy
Cumulus**.

### Defining a Collection

Once a provider is defined, you may define a collection indicating a number of
details regarding how to derive the granule IDs from the names of the files
comprising the granules in the collection, along with the specific files for
each granule, among other things.

Collection definitions are stored in this project's
`app/stacks/cumulus/resources/collections` directory, and the recommended
filename convention for a collection definition is `<COLLECTION_ID>.json`, where
`<COLLECTION_ID>` is constructed as
`<COLLECTION_SHORT_NAME>___<COLLECTION_VERSION>`, which uses 3 underscores to
align with Cumulus's convention for constructing "collection IDs" (e.g.,
`PSScene3Band___1.json`).

There are a number of [collection] properties, but below is an example of the
recommended collection definition structure for collections in this project:

```json
{
  "name": "<COLLECTION_SHORT_NAME>",
  "version": "<COLLECTION_VERSION>",
  "duplicateHandling": "skip",
  "granuleId": ".*",
  "granuleIdExtraction": "^(<GRANULE_ID_PATTERN>)(?:<SUFFIX_PATTERN>)$",
  "sampleFileName": "<SAMPLE_GRANULE_ID><SAMPLE_SUFFIX>",
  "url_path": "{cmrMetadata.CollectionReference.ShortName}___{cmrMetadata.CollectionReference.Version}/{cmrMetadata.GranuleUR}",
  "ignoreFilesConfigForDiscovery": true,
  "files": [
    {
      "regex": "^(<GRANULE_ID_PATTERN>)(?:<SUFFIX_PATTERN>)$",
      "sampleFileName": "<SAMPLE_GRANULE_ID><SAMPLE_SUFFIX>",
      "bucket": "protected"
    }
  ],
  "meta": {
    "prefixGranuleIds": "<BOOLEAN>"
  }
}
```

where:

- `<COLLECTION_SHORT_NAME>` is the short name of the collection (e.g.,
  `"PSScene3Band"`)
- `<COLLECTION_VERSION>` is the version of the collection (e.g., `"1"`)
- `<GRANULE_ID_PATTERN>` is a regular expression matching the part of each
  filename that represents the granule ID of the granule to which the file
  belongs
- `<SUFFIX_PATTERN>` is a regular expression matching the suffix of each
  filename
- `<SAMPLE_GRANULE_ID>` is an example of a granule ID that matches the
  `<GRANULE_ID_PATTERN>` regular expression
- `<SAMPLE_SUFFIX>` is an example of a filename suffix that matches the
  `<SUFFIX_PATTERN>` regular expression
- the `"url_path"` property value is the S3 key prefix to use for the
  destination location of the granule files.  See
  [How to specify a file location in a bucket] for details on how to construct a
  template value for this property.
- although the `"files"` list contains only a single entry, it should match
  _every_ file for a given granule (this is for convenience, so that we do not
  have to specify a separate entry for every possible file of a granule)
- the `"files"/"regex"` property value should be the same as the top level
  `"granuleIdExtraction"` property value (again, for convenience)
- the `"files"/"sampleFileName"` property value should match the top level
  `"sampleFileName"` property value (again, for convenience)
- the `"meta/prefixGranuleIds"` property value is optional, and defaults to
  `false`.  If specified, it should be either `true` or `false`.  Note that this
  is a _boolean_ value, and thus must _not_ be enclosed in quotes.  If set to
  `true`, during discovery, the granule ID extracted from the name of a file
  (via the `"granuleIdExtraction"` regular expression) will be prefixed with the
  name of the collection (as specified by the `"name"` property in this
  definition file), separated by a dash (`"-"`).  For example, if the collection
  name is `"MyCollection"`, and the granule ID extracted from a granule file's
  name is `"12345"`, the granule ID will be modified to be
  `"MyCollection-12345"`.  This feature is a naive accomodation for granules
  where the `"GranuleUR"` property within a granules UMM-G metadata file
  (`"*cmr.json"`) does _not_ match the granule ID that Cumulus extracted from
  the file name (which is an assumption made within Cumulus).  Rather, the
  `"GranuleUR"` value is in the format just described.  Such is the case for the
  PSScene3Band collection, so that collection explicitly sets this property to
  `true`.  This is generally not the case, so it is generally unlikely that this
  property needs to be set.  Further, if the `"GranuleUR"` differs from the
  extracted granule ID in some other way, this naive accomodation won't work,
  and further logic will be required.

The trickiest part of configuring a collection is determining the regular
expression to use for extracting the granule ID from a filename.  For examples,
refer to existing files under `app/stacks/cumulus/resources/collections`.  For
testing regular expressions, there are various online resources, such as
<https://regex101.com/>.

Once a collection `.json` file is created, you can add it to the Cumulus
database (or update it) with the following command (from within the Docker
container):

```sh
cumulus collections upsert --data \
  app/stacks/cumulus/resources/collections/<COLLECTION_ID>.json
```

**REMINDER:** To run `cumulus` commands against a non-development Cumulus
deployment, see
[Running Against Non-Development Deployments](#running-against-non-development-deployments).

### Defining a Rule

Finally, once a _provider_ and a _collection_ are defined, you can define a
[rule] to trigger discovery and ingestion of the collection's granule files from
the provider.

Similarly to providers and collections, rule definitions should be placed in the
`app/stacks/cumulus/resources/rules` directory and named like
`<RULE_NAME>.json`, where `<RULE_NAME>` is the value of the `"name"` property in
the rule definition.

The following is the recommended structure of a rule definition for this
project (with details below):

```json
{
  "name": "<RULE_NAME>",
  "state": "DISABLED",
  "provider": "<PROVIDER_ID>",
  "collection": {
    "name": "<COLLECTION_SHORT_NAME>",
    "version": "<COLLECTION_VERSION>"
  },
  "workflow": "DiscoverAndQueueGranules",
  "rule": {
    "type": "onetime"
  },
  "meta": {
    "startDate": "<START_DATE>",
    "endDate": "<END_DATE>",
    "step": "P1D",
    "providerPathFormat": "<DATE_FORMAT_PATTERN>",
    "discoverOnly": false
  }
}
```

where:

- `<RULE_NAME>` is the name of the rule, with a recommended format of
  `<COLLECTION_ID>`, if the rule will cause ingestion of the _entire_
  collection, or `<COLLECTION_ID>_<SUFFIX>`, where `<SUFFIX>` is some sort of
  qualifier indicating which portion of the collection it will ingest (e.g., a
  4-digit year if it will ingest a specific year of granule files, as controlled
  by the `"meta"` properties described below)
- `<PROVIDER_ID>` is the ID of the provider from which to discover/ingest files.
  This must match the `"id"` property in one of the provider definition files,
  as covered above in [Defining a Provider](#defining-a-provider).
- `<COLLECTION_SHORT_NAME>` is the short name of the collection to
  discover/ingest
- `<COLLECTION_VERSION>` is the version of the collection to discover/ingest
- the `"meta"` properties limit which files will be discovered/ingested, as
  detailed below

The details for setting the `"meta"` properties appropriately are a bit more
involved because we have implemented custom discovery logic, both for the code
in the `DiscoverGranules` task (see `src/lib/discovery.ts`) and the
`DiscoverAndQueueGranules` workflow (see
`app/stacks/cumulus/templates/discover-granules-workflow.asl.json`) in order to
work around a severe scalability limitation in the core Cumulus implementation.

Within the `"meta"` section shown in the JSON definition template above:

- `<START_DATE>` is an [ISO 8601 Combined date and time representation], which
  should end with a `Z` to indicate UTC time (e.g., 2017-08-01T00:00:00Z).
- `<END_DATE>` is an [ISO 8601 Combined date and time representation] (the date
  range _excludes_ this date), which should end with a `Z` to indicate UTC time.
- the `"step"` property value is an [ISO 8601 Duration], and should generally be
  set to `"P1D"` (representing a duration of 1 day) to avoid crashing the
  `DiscoverGranules` task for collections that may include large numbers of
  granule files in any given month.  For very small collections (perhaps a max
  of 10K per month), this could be set to `"P1M"`, representing a duration of 1
  month, but only if the file naming convention supports such resolution.
- `<DATE_FORMAT_PATTERN>` is a [date format pattern] that is used to format the
  dates produced by starting with `<START_DATE>` and incrementing the date by
  the `"step"` value until the `<END_DATE>` is reached.  Each formatted result
  is used as the "provider path" that Cumulus uses to determine the S3 key
  prefix (within the S3 bucket specified by the provider identified by
  `<PROVIDER_ID>`) where it will discover files.  Typically, this pattern should
  be in the form `"'path/to/collection/'<DATE_PATTERN>"`, where
  `"'path/to/collection'"` represents the literal path that is the part of the
  prefix that does not contain date information (and **must be surrounded by
  single quotes** to avoid having any characters interpreted as part of a date
  pattern), and `<DATE_PATTERN>` is the subsequent part of the path that
  contains date information.  For example, for the PSScene3Band collection, this
  might be `"'planet/PSScene3Band'yyyyMMdd"`, where `'planet/PSScene3Band'` is
  the literal part, and `yyyyMMdd` represents the 4-digit year (`yyyy`, _not_
  `YYYY`), 2-digit month (`MM`) and 2-digit day of the month (`dd`).  This
  should have the same granularity as the `"step"` duration.  For example, if
  `"step"` is set to 1 day (`"P1D"`), this date format must also have a
  resolution of 1 day.

Once a rule `.json` file is created, you can add it to the Cumulus database (or
update it) with the following command (from within the Docker container):

```plain
cumulus rule upsert --data \
  app/stacks/cumulus/resources/rules/<RULE_NAME>.json
```

**REMINDER:** To run `cumulus` commands against a non-development Cumulus
deployment, see
[Running Against Non-Development Deployments](#running-against-non-development-deployments).

## Ingesting a Collection

### Triggering Discovery and Ingestion

Triggering discovery and ingestion is simply a matter of enabling and running a
rule (or set of rules) for a collection.

If you have not _enabled_ the rule you wish to run, you must do so first.  Since
we'll use the Cumulus CLI to enable and run rules, make sure you're using the
Docker terminal, if not already doing so:

```plain
make bash
```

To _enable_ a rule, run the following command.  If you are unsure whether or not
the rule is already enabled, running the following command will work either way:

```plain
cumulus rule enable --name <RULE_NAME>
```

To _run_ a rule, run the following command:

```plain
cumulus rule run --name <RULE_NAME>
```

### Viewing CloudWatch Logs

To monitor the operation of the workflows triggered by running Cumulus rules,
you can tail the relevant CloudWatch logs using the AWS CLI from within the
Docker container. Most commonly, we'll want to view the following logs:

- `/aws/lambda/${CUMULUS_PREFIX}-DiscoverGranulesPrefixingIds`
- `/aws/lambda/${CUMULUS_PREFIX}-QueueGranules`
- `/aws/lambda/${CUMULUS_PREFIX}-PostToCmr`

Again, to open a terminal in the Docker container, run the following:

```plain
make bash
```

The AWS CLI command to tail and follow log is as follows (where `LOG_NAME` is
one of the log names listed above, or some other relevant log name):

```plain
aws logs tail --follow LOG_NAME
```

Since the ECS logs can contain a lot of extraneous "heartbeat" messages, it can
sometimes be difficult to wade through the messages to find the relevant ones.
For the `${CUMULUS_PREFIX}-DiscoverGranulesEcsLogs` log, we typically want to
know only how many granules were discovered. Therefore, the following command
selects the relevant log message details:

```sh
aws logs tail \
  --format short \
  --follow \
  --filter-pattern '{ $.message = "Discovered *" }' \
  ${CUMULUS_PREFIX}-DiscoverGranulesEcsLogs
```

As granules are discovered, they are then queued so that they can then be
ingested. When successful, the queueing step does not log any meaningful
messages, so the only time you'll want to view the logs for this step is when a
workflow has failed and you're looking for error messages in the various logs.
To view the logs for the queueing step, run the following:

```sh
aws logs tail \
  --format short \
  --follow \
  ${CUMULUS_PREFIX}-QueueGranulesEcsLogs
```

After discovery and queueing, we may want to observe CMR activity to confirm
that CMR requests are succeeding:

```sh
aws logs tail \
  --format short \
  --follow \
  --filter-pattern '{ $.message = "Published UMMG *" }' \
  /aws/lambda/${CUMULUS_PREFIX}-PostToCmr
```

### Performing Discovery without Ingestion

To aid in debugging of a rule's configuration, or to verify the expected list of
granules from "discovery" only, the `DiscoverAndQueueGranules` workflow also
supports a `"meta.discoverOnly"` flag (boolean value) to disable or enable
subequent ingestion.  When a rule's `"meta.discoverOnly"` flag is set to `true`,
the workflow exits after the "discovery" step, thus avoiding queueing the
discovered granules (and thus avoiding ingestion and publication to the CMR).
When the flag is missing or explicitly set to `false`, execution proceeds
normally (i.e., granules are queued for ingestion) through the remaining steps
of the workflow.

For example:

```json
{
  "name": "<RULE_NAME>",
  ...,
  "meta": {
    ...,
    "discoverOnly": true
  }
}
```

Note, however, that due to yet another Cumulus bug, once any value is set
within a rule's `"meta"` section, it cannot simply be removed in order to
remove the effect of the setting.  Rather, a _different value_ must be set, as
removing the entry from the `"meta"` section does _not_ remove it from the
database.

For example, once `"discoverOnly"` is added to the `"meta"` section, it cannot
simply be removed to _implicitly_ set it to `false` (the default value)
because the `"meta.discoverOnly"` value will _not_ be removed from the database.
Instead, you must now _explicitly_ set the value to `false` to _disable_
"discover only" mode:

```json
{
  "name": "<RULE_NAME>",
  ...,
  "meta": {
    ...,
    "discoverOnly": false
  }
}
```

## Destroying a Deployment

**CAUTION:** Before starting any destructive steps, be sure you are working
against the correct deployment to avoid accidentally destroying resources in the
wrong deployment.

### Destroying Managed Resources

At a high level, destroying a Cumulus deployment is relatively straightforward,
but there are some resource dependencies that may present difficulties.
Therefore, to make it easy simply run the following command, which will prompt
you for confirmation first, to avoid accidentally destroying a deployment:

```sh
make nuke
```

After confirmation (you will have an opportunity to abort), this will destroy
all resources managed by Terraform in all of the modules (`cumulus`, then
`data-persistence`, and finally `rds-cluster`), so it will take quite a bit of
time to complete.

**NOTE:** If you encounter any errors during destruction, refer to the
[troubleshooting guide](./TROUBLESHOOTING.md).

### Destroying Unmanaged Resources

In addition to the resources managed by Terraform, there are a number of
additional resource (not managed by Terraform).  If you do not plan to redeploy
Cumulus after destroying the managed resources, as described in the previous
section, then you should destroy the unmanaged resources as well.

There are several buckets that should be destroyed.  To see the list of buckets
related to your deployment, run the following:

```sh
aws s3 ls | grep ${CUMULUS_PREFIX}
```

To delete a bucket, run the following, where `<NAME>` is a name from the buckets
listed from the previous command:

```sh
aws s3api delete-bucket --bucket <NAME>
```

There are also several SSM Parameters that must be cleaned up.  To list them,
run the following:

```sh
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Option=Contains,Values=/${TS_ENV}/" \
  --query Parameters[].Name
```

For each name in the list, run the following command to delete the parameter,
where `<NAME>` is a name from the output of the previous command:

```sh
aws ssm delete-parameter --name <NAME>
```

Again, if you encounter any errors during any of these steps, refer to the
[troubleshooting guide](./TROUBLESHOOTING.md).

## Appendix

### Skip Granule Discovery for Disabled Rules

A [rule] in Cumulus is used to trigger a data processing pipelines (workflow).
There are several types of rules, but in particular, a rule of type `"onetime"`
is used to manually trigger a workflow (an AWS Step Function).  Further, a rule
has a `state` property (among others), which must be either `"ENABLED"` or
`"DISABLED"`.

However, there is a
[bug in Cumulus](https://bugs.earthdata.nasa.gov/browse/CUMULUS-2985), where
adding a new `"onetime"` rule via the Cumulus API _immediately_ triggers
execution of the associated workflow (Step Function), even when the new rule's
`state` is initially set to `"DISABLED"`.

As a workaround to the bug described above, to prevent _immediate_ triggering of
a "discovery" workflow by the creation of a _disabled_ rule, we have added a
Choice step as the initial step of our `DiscoverAndQueueGranules` Step Function
that immediately ends execution _unless_ the input to the step contains the
value `"ENABLED"` at the path `"$.meta.rule.state"`.

However, because Cumulus copies _only_ the values within a rule definition's
`meta` section to the `$.meta` section of a workflow's input, by default, a
workflow has no means to determine which rule triggered it, and thus cannot
determine whether or not the triggering rule's state is `"ENABLED"`.

Therefore, until Cumulus is enhanced to include the rule in the `$.meta`
section of the workflow input (just as it already includes the `provider` and
`collection`), we must _manually duplicate_ within a rule's `meta` section any
rule properties outside of the `meta` section that we wish to have access to
within a workflow.

For example, **the following is necessary for every new `"onetime"` rule**
(assuming that we do **not** want to trigger execution of the rule's `workflow`
at rule-creation time, which we likely do not want to do):

1. Create the rule (via the Cumulus API), with the `state` property set to
   either `"DISABLED"` (the value doesn't matter because of the Cumulus bug
   described above). For example, you might use the Cumulus CLI, like so:

   ```sh
   cumulus rules add --data '{
     "name": "<RULE_NAME>",
     "state": "DISABLED",
     ...
     "rule": {
       "type": "onetime"
     },
     ...
   }'
   ```

   When this rule is added, the Step Function specified via the `"workflow"`
   property will be triggered, but since this rule does not include a value at
   the path `"meta.rule.state"`, the initial Choice step in the Step Function
   will cause the workflow to exit immediately, with no actions performed.

1. Update (replace) the rule (via the Cumulus API), setting the `"state"` value
   to `"ENABLED"`, and also adding the value `"ENABLED"` at the path
   `"meta.rule.state"`. To do this via the Cumulus CLI, simply run the following
   command:

   ```plain
   cumulus rules enable --name my_rule
   ```

   This will **not** trigger the workflow again because updates (replacements)
   do not trigger executions.

Note that it is not strictly necessary to set `"state"` to `"ENABLED"` since
this value is completely (and erroneously) ignored by Cumulus.  The only value
that matters for our workaround is the value of `"meta.rule.state"`.  However,
for consistency (and to avoid potential confusion), the value of `"state"` and
`"meta.rule.state"` should be the same (when `"meta.rule.state"` is added or
changed).

At this point, the Cumulus API must be used to run the rule again (after the
initial execution triggered at rule-creation time). This can be achieved via the
Cumulus CLI as follows:

```sh
cumulus rules run --name my_rule
```

[Cumulus API]:
  https://nasa.github.io/cumulus-api/
[Cumulus CLI]:
  https://github.com/NASA-IMPACT/cumulus-cli
[Cumulus Data Management Types]:
  https://nasa.github.io/cumulus/docs/configuration/data-management-types
[collection]:
  https://nasa.github.io/cumulus/docs/data-cookbooks/setup#collections
[date format pattern]:
  https://www.unicode.org/reports/tr35/tr35-dates.html#8-date-format-patterns
[provider]:
  https://nasa.github.io/cumulus/docs/operator-docs/provider
[rule]:
  https://nasa.github.io/cumulus/docs/data-cookbooks/setup#rules
[How to specify a file location in a bucket]:
  https://nasa.github.io/cumulus/docs/workflows/workflow-configuration-how-to#how-to-specify-a-file-location-in-a-bucket
[ISO 8601 Combined date and time representation]:
  https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
[ISO 8601 Duration]:
  https://en.wikipedia.org/wiki/ISO_8601#Durations
