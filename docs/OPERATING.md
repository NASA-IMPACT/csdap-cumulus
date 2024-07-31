# Operating CSDAP Cumulus

- [Update Launchpad Certificate](#update-launchpad-certificate)
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
- [Updating CMR Metadata (Self Discovery)](#updating-cmr-metadata-self-discovery)
- [Destroying a Deployment](#destroying-a-deployment)
- [Cognito Integration](#cognito-integration)
  - [Updating Vendor Based Data Access Filter](#updating-vendor-based-data-access-filter)



## Update Launchpad Certificate

When the Launchpad certificate used for generating auth tokens for publishing
metadata to the CMR has expired, the `PostToCmr` Lambda function will always
fail with 401 (Unauthorized) errors.  When this happens (ideally, _BEFORE_ it
expires, so `PostToCmr` does _not_ start throwing such errors), the Project
Owner must request a new certificate.  Once the request is fulfilled, the
Project Owner should receive a new certificate file (`.pfx`) as well as a new
passphrase/password.

For every AWS account in which CSDA Cumulus is deployed (sandbox, UAT, and
Prod), the new Launchpad certificate file and its associated passcode must be
updated _once_ per AWS account (regardless of the number of deployments in an
account), using the following commands, where `<pfx>` is the path to the new
Launchpad certificate file (`.pfx`) downloaded from the email resulting from the
completion of the renewal request, relative to your current directory (which
must be the root of the repo).

You will be prompted for the passcode each time:

```plain
export LAUNCHPAD_PFX=<pfx>
AWS_PROFILE=csda-cumulus-sbx-7894 make update-launchpad
AWS_PROFILE=csda-cumulus-uat-1686 make update-launchpad
AWS_PROFILE=csda-cumulus-prod-5047 make update-launchpad
```

Once all of the commands above run successfully, be sure to delete your local
copy of the `.pfx` file, for security reasons.

The command above does the following in the AWS account associated with the
specified AWS profile:

1. Verifies that the specified certificate/passcode combination are valid by
   using them in an attempt to generate a Launchpad token.  If successful, the
   command continues with the following steps.  Otherwise, it fails with an
   error message.  Failure might typically be because you have entered the
   passcode incorrectly, so upon failure, you should double-check the passcode.
1. Creates/updates an AWS binary secret named `cumulus-launchpad-pfx` from the
   contents of the specified `.pfx` file.
1. Creates/updates an AWS SSM secret string parameter named
   `/cumulus/shared/launchpad-passcode` from the passcode entered at the prompt.

Once the certificate and passcode are updated, each deployment must be
_redeployed_ in order to pick up the new certificate and passcode.  During
redeployment, the new value of the `cumulus-launchpad-pfx` secret will be used
to create/replace the S3 object `<prefix>/crypto/launchpad.pfx` within the
deployment's "system" bucket (typically the "internal" bucket).  This is where
Cumulus expects to find the Launchpad certificate.

For sandbox deployments, each developer should redeploy their own deployment
by running `make up-cumulus-yes`.

To redeploy UAT and Prod, do the following:

1. Go to the list of [GitHub Actions Cumulus workflow runs]
1. Find the most recent successful workflow run (ideally, this will be the first
   one in the list) and click its title to view the details of the run, where
   you should see that deployment to UAT and to Prod both ran successfully.
1. Towards the upper right of the page, click the **Re-run all jobs** button to
   trigger deployment to UAT.
1. Once deployment to UAT succeeds, deployment to Prod will be pending manual
   approval.  At this point, run a smoke test in UAT to determine whether or not
   the `PostToCmr` Lambda function succeeds.
1. Once the smoke test in UAT shows that `PostToCmr` succeeds, return to the
   page where you previously clicked the **Re-run all jobs** button, where you
   should now see a **Review deployments** button.
1. Click the **Review deployments** button to open the "Review pending
   deployments" dialog box.
1. On the dialog box, check the box next to "prod", then click the **Approve and
   deploy** button.
1. Once deployment to "prod" succeeds, run a smoke test to confirm successful
   operation of the `PostToCmr` Lambda function.

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

Due to the Cumulus discovery scalability issue described in
[DISCOVERY.md](./DISCOVERY.md), we make use of `hygen` for generating rule
definitions, as we typically need to generate one rule definition per year per
collection. To generate a rule definition, run `make bash` to enter a Docker
terminal session, then run `hygen rule new` and follow the prompts.
After running `hygen`, it will output a command line version of what was
just entered. This can be used to repeat the process easily by changing
only what is needed.
Here is an example of using command line parameters to make a rule:
`hygen rule new --provider maxar --collectionName WV03_MSI_L1B --collectionVersion 4 --providerPathFormat "'css/nga/WV03/1B/'yyyy/DDD" --year 2015`

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

## Updating CMR Metadata (Self Discovery)

For cases where we need to update CMR metadata files for granules we have
already ingested, we can perform "self discovery."  This simply means that we
can leverage existing rules (or create new ones, if necessary) to "discover"
granule files from our own buckets, where we have already ingested the granule
files.

For example, before we obtained custom (friendly) domain names to use for our
UAT and Prod distribution URLs, we were using CloudFront URLs, and setting the
value of the `cumulus_distribution_url` Terraform variable for each environment
to a CloudFront URL.  Unfortunately, an issue occurred in the Earthdata Cloud
(EDC) infrastructure that caused our Prod CloudFront Distribution to be blown
away, thus requiring us to update the value of the `cumulus_distribution_url`
for Prod to a different URL.

This also meant that we had to update the links in the CMR metadata files that
we had already published up to that point in time, which was over 4 million CMR
files!

However, instead of setting the value of `cumulus_distribution_url` to the new
CloudFront URL that EDC created for us, we took the opportunity to request
custom domain names (for UAT and Prod) that sit in front of the CloudFront
Distributions, so that we could update the links in the 4 million CMR metadata
files to use the new custom domain names.  This not only means that the
distribution URLs are now friendlier (i.e., no "random" CloudFront domain
names), but also, if such an issue ever occurs again, we do not have to update
the CMR again.  We would simply make a request to point the custom domain to a
different CloudFront URL.

Now, perhaps the only reason we might have to update the CMR files again is if
we were to change the custom domain names.  If such a situation were to arise
again, where we would need to update the links in the CMR files again, here is
what we did to minimize the effort:

1. Added the `"ingestedPathFormat"` meta property to every rule, which is the
   corollary of the `"providerPathFormat"` meta property.  This should be set
   similarly to `"providerPathFormat"`, but use the path that corresponds to the
   location of granule files ingested into the protected bucket.
1. Modified the `"DiscoverAndQueueGranules"` workflow by adding the
   `"SelfDiscovery?"` state (step), which compares the provider host value (at
   the path `$.meta.provider.host`) to the protected bucket name (at the path
   `$.meta.buckets.protected.name`) in order to determine whether or not "self
   discovery" is occurring.  If the two values are equal, then "self discovery"
   is under way, and the value of `$.meta.ingestedPathFormat` is substituted in
   place of `$.meta.providerPathFormat` so that discovery uses the appropriate
   path within the protected bucket.

In order to cause "self discovery" to occur, take the following steps (which are
applicable to either UAT or Prod):

1. Copy thumbnails from the public bucket to the protected bucket:
   - In UAT, there are relatively few files, so this can be achieved either via
     the AWS Console or the AWS CLI.
   - In Prod, this must be done by first creating an S3 inventory of the public
     bucket, and then running an S3 Batch copy using the generated inventory to
     copy the files to the protected bucket.
1. Update the `host` value for the relevant provider(s).  For example, to update
   the `planet` provider in UAT:

   ```plain
   DOTENV=.env.uat make bash
   cumulus providers replace --data \
     '{"id":"planet", "protocol":"s3", "host":"'csda-${CUMULUS_PREFIX}-protected-7894'"}'
   ```

1. Run the relevant rule(s)
1. Restore the `host` value for the relevant provider(s).  For example, to
   restore the `planet` provider in UAT:

   ```plain
   DOTENV=.env.uat make bash
   cumulus providers replace --data app/stacks/cumulus/resources/providers/planet.json
   ```

1. Optionally, delete the thumbnails from the protected bucket.  However, there
   is no straightforward and efficient way to bulk delete very large numbers of
   S3 objects with keys matching a pattern.  Although it is possible to use the
   `aws s3 rm` command with an `--include` pattern, this is likely to be
   extremely inefficient for deleting millions of thumbnails from the Production
   protected bucket (but perhaps not).  **IMPORTANT:** If attempting to use
   `aws s3 rm` with an `--include` pattern, also use the `--dryrun` option to
   first check that you _won't_ delete files _other_ than the thumbnails.

## Destroying a Deployment

**CAUTION:** Before starting any destructive steps, be sure you are working
against the correct deployment to avoid accidentally destroying resources in the
wrong deployment.

At a high level, destroying a Cumulus deployment is relatively straightforward,
but there are some resource dependencies that may present difficulties.
Therefore, to make it easy simply run the following command, which will prompt
you for confirmation first, to avoid accidentally destroying a deployment:

```sh
make nuke
```

After confirmation (you will have an opportunity to abort), this will destroy
all resources managed by Terraform in all of the modules (`post-deploy-mods`, then `cumulus`, then
`data-persistence`, and finally `rds-cluster`), so it will take quite a bit of
time to complete.

The `nuke` script has some rudimentary retry logic built in, but it's not
bulletproof, so it may fail after multiple retries.  You may need to inspect any
error messages carefully to determine whether you can run `make nuke` again, or
you must manually finish any cleanup effort.

**NOTE:** If you encounter any errors during destruction, refer to the
[troubleshooting guide](./TROUBLESHOOTING.md).

## Cognito Integration
Cognito Integration path through Cumulus for a user to get data:
- A request is made for data which hits the lambda endpoint named cumulus-<ENV>-DistributionApiEndPoints
- If the request is for an S3 file, then it gets forwarded to ESDIS Cognito System for User Login
- After the User has a successful login, the request then comes back to cumulus-<ENV>-DistributionApiEndPoints where the file is served.
- Note: There is a custom layer in pre-filter-DistributionApiEndpoints where a user's vendor access variable is checked before allowing or denying the file access.

Related AWS Components and Configuration
- API Gateway Connected to Lambda
- Lambda cumulus-<ENV>-DistributionApiEndPoints
- Lambda pre-filter-<ENV>-DistributionApiEndPoints
- CloudFront Distribution Configuration 
  - Under Origins, there should be a path that points to an origin domain that begins with `s3-`
  - This part of the config happens on the ESDIS side.

Vendor Based Access to Datasets
- CSDA Admin Staff are able to configure which user has access to which vendor (this process may even be automated in another system)
- On the ESDIS side, the custom property contain the list of allowed Vendors is attached to the user upon authentication
- On this side, within pre-filter-<ENV>-DistributionApiEndpoints, the request is checked against the access list and the request is either denied, or allowed to proceed.
- Each Vendor has its own set of subdirectories which correspond to datasets.
- The pre-filter-<ENV>-DistributionApiEndpoints lambda is packaged up and sent to AWS via the 4th module named `post-deploy-mods`
  - Note: The Deployment in Terraspace was configured so the deployment of post-deploy-mods happens AFTER the `cumulus` module.  
If this deployment happens before the `cumulus` module, then the vendor filter function will not be located in its proper place at the back end of the API Gateway for Distribution Endpoints.  


### Updating Vendor Based Data Access Filter

Directly in the Code:
- Note: It is better to update the local copy of the code rather than AWS deployed version.  See section below.
- Log in to the AWS Dashboard (Testing only works in UAT or PROD since there is no sandbox set up with ESDIS cognito authentication)
- Browse to the Lambda functions on AWS.
  - Search for "pre-filter-DistributionApiEndpoints"
  - Search URL: https://us-west-2.console.aws.amazon.com/lambda/home?region=us-west-2#/functions?fo=and&o0=%3A&v0=pre-filter-DistributionApiEndpoints
- Open the Lambda function and view. 
 - On UAT this function is called, "cumulus-uat-pre-filter-DistributionApiEndpoints" 		// https://us-west-2.console.aws.amazon.com/lambda/home?region=us-west-2#/functions/cumulus-uat-pre-filter-DistributionApiEndpoints?tab=code
 - On PROD this function is called, "cumulus-prod-pre-filter-DistributionApiEndpoints" 	// https://us-west-2.console.aws.amazon.com/lambda/home?region=us-west-2#/functions/cumulus-prod-pre-filter-DistributionApiEndpoints?tab=code
- Edit the code, by following the steps under "Updating the Code definition to add a new vendor"
- When code updates are completed, make sure to save (ctrl+s) and then click on Deploy

Updating the Code definition to add a new vendor
- Edit the local copy of the Code (found in `apps/stacks/post-deploy-mods/resources/lambdas/pre-filter-DistributionApiEndpoints/src/lambda_function.py` )
  - Look for a variable named: `vendor_to_dataset_map`
This is a python dictionary.  The top level keys are vendor names.
At the time of this writing, the current vendor names are: `planet` and `maxar`.
The value after each of these vendor names is an array which lists the top level directories where that vendor's datasets are found.
For example, under the vendor `maxar` we have multiple datasets which have S3 directory names of: `['WV04_MSI_L1B___1', 'WV04_Pan_L1B___1','WV03_MSI_L1B___1', 'WV03_Pan_L1B___1','WV02_MSI_L1B___1', 'WV02_Pan_L1B___1','WV01_MSI_L1B___1', 'WV01_Pan_L1B___1','GE01_MSI_L1B___1', 'GE01_Pan_L1B___1']`
  - To add a new vendor (`testvendor`), 
    - create a new top level key such as `testvendor`
    - next, add an array containing all of the subdirectories for that vendor.
      - If there is only 1 to add, it will be a single element string array. 
Example:  `'testvendor': ['tv01_data']` 	// Adding a vendor called, `testvendor` with a single dataset directory called, `tv01_data`.
  - Important Note. The vendor names should be lowercase and have no spaces or non-alpha numeric characters.  The first character should not be a number.  Not following this note may lead to errors for users attempting to download data.
      


END 



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
[GitHub Actions Cumulus workflow runs]:
  https://github.com/NASA-IMPACT/csdap-cumulus/actions/workflows/main.yml
[How to specify a file location in a bucket]:
  https://nasa.github.io/cumulus/docs/workflows/workflow-configuration-how-to#how-to-specify-a-file-location-in-a-bucket
[ISO 8601 Combined date and time representation]:
  https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations
[ISO 8601 Duration]:
  https://en.wikipedia.org/wiki/ISO_8601#Durations
