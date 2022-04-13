# Operating CSDAP Cumulus

- [Cumulus CLI](#cumulus-cli)
  - [Using the Cumulus CLI](#using-the-cumulus-cli)
  - [Running Workflows](#running-workflows)
- [Granule Discovery and Ingestion](#granule-discovery-and-ingestion)
  - [Creating Cumulus "Onetime" Rules](#creating-cumulus-onetime-rules)
  - [Skip Granule Discovery for Disabled Rules](#skip-granule-discovery-for-disabled-rules)
  - [Viewing CloudWatch Logs](#viewing-cloudwatch-logs)
  - [Performing Discovery without Ingestion](#performing-discovery-without-ingestion)
- [Destroying a Deployment](#destroying-a-deployment)
  - [Destroying Managed Resources](#destroying-managed-resources)
  - [Destroying Unmanaged Resources](#destroying-unmanaged-resources)

## Cumulus CLI

The Cumulus CLI provides a means for using the [Cumulus API][3] from the
command-line, rather than via the Cumulus Dashboard, which is particularly
useful when the Dashboard is not deployed.

However, the CLI does not provide complete coverage of the Cumulus API, nor does
it provide as much functionality as the Dashboard. Rather, it is focused on
supporting a small number of common management functions, such as managing
providers, collections, and rules (see [Cumulus Data Management Types][4]).

Ideally, the Cumulus CLI should be developed as an independent tool, but for
now, it resides within this repository, and requires `yarn` and `node` to run.
However, to avoid the need to install `yarn` and `node` locally, you may run the
CLI from within the Docker container, as described below.

### Using the Cumulus CLI

To run Cumulus CLI commands within the Docker container, first start a `bash`
session within the container as follows:

```sh
make docker  # If you haven't already done so
make bash
```

Within the container, Cumulus CLI commands have the following general form:

```plain
./cumulus <subcommand> <options>
```

To see the available subcommands, run the following:

```plain
./cumulus --help
```

To get help for a particular subcommand, run the following:

```plain
./cumulus <subcommand> --help
```

### Running Workflows

Cumulus workflows are simply AWS Step Functions, and they are triggered by
running _rules_ defined in the Cumulus deployment.

Once a rule is defined, you can run the rule to trigger the workflow specified
in the rule definition using the following command, where `NAME` is the name of
the rule (also specified in the rule definition):

```sh
./cumulus rules run --name NAME
```

**NOTE:** To get started with some test data in a development deployment, first,
start a `bash` session in the Docker container (if you haven't already done so):

```sh
make bash
```

Then, load the test data by running the following command (this may take a few
minutes to complete):

```sh
bin/create-test-data.sh
```

The script uses the Cumulus CLI to add a provider, a collection, a rule, and a
few granule files to your deployment. Once the script finishes, it will output
detailed steps to follow for enabling the rule, running the rule, and checking
the logs.

Note that in development deployments, CMR metadata is only _validated_ against
the UAT CMR. It is not _published_ to the CMR.

## Granule Discovery and Ingestion

### Creating Cumulus "Onetime" Rules

[Rules in Cumulus][1] are used to trigger data processing pipelines (workflows).
There are several types of rules, but in particular, a rule of type `"onetime"`
is used to manually trigger a workflow (an AWS Step Function).  Further, a rule
has a `state` property (among others), which must be either `"ENABLED"` or
`"DISABLED"`.

However, there is a bug in Cumulus, where adding a new `"onetime"` rule via the
Cumulus API (either directly or through the Cumulus Dashboard) _immediately_
triggers execution of the associated workflow (Step Function), even when the
new rule's `state` is initially set to `"DISABLED"`.

### Skip Granule Discovery for Disabled Rules

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
   ./cumulus rules add --data '{
     "name": "my_rule",
     "state": "DISABLED",
     "rule": {
       "type": "onetime"
     },
     "workflow": "DiscoverAndQueueGranules",
     "provider": "my_provider",
     "collection": "my_collection"
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
   ./cumulus rules enable --name my_rule
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
./cumulus rules run --name my_rule
```

### Viewing CloudWatch Logs

To monitor the operation of the workflows triggered by running Cumulus rules,
you can tail the relevant CloudWatch logs using the AWS CLI from within the
Docker container. Most commonly, we'll want to view the following logs:

- `${CUMULUS_PREFIX}-DiscoverGranulesEcsLogs`
- `${CUMULUS_PREFIX}-QueueGranulesEcsLogs`
- `/aws/lambda/${CUMULUS_PREFIX}-PostToCmr` (non-development stacks)

Again, to open a terminal in the Docker container, run the following:

```sh
make bash
```

The AWS CLI command to tail and follow log is as follows (where `LOG_NAME` is
one of the log names listed above, or some other relevant log name):

```sh
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
  "name": "my_rule",
  "state": "ENABLED",
  "rule": {
    "type": "onetime"
  },
  "workflow": "DiscoverAndQueueGranules",
  "provider": "my_provider",
  "collection": "my_collection",
  "meta": {
    "discoverOnly": true,
    "rule": {
      "state": "ENABLED",
    }
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
  "name": "my_rule",
  "state": "ENABLED",
  "rule": {
    "type": "onetime"
  },
  "workflow": "DiscoverAndQueueGranules",
  "provider": "my_provider",
  "collection": "my_collection",
  "meta": {
    "discoverOnly": false,
    "rule": {
      "state": "ENABLED",
    }
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

[1]: https://nasa.github.io/cumulus/docs/v9.3.0/data-cookbooks/setup#rules
[2]: https://nasa.github.io/cumulus-api/#updatereplace-rule
[3]: https://nasa.github.io/cumulus-api/
[4]: https://nasa.github.io/cumulus/docs/configuration/data-management-types
