# Operating CSDAP Cumulus

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
choice step as the initial step of our `DiscoverAndQueueGranules` Step Function
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
(assuming that we do **not** want to trigger execution of the
`"DiscoverAndQueueGranules"` Step Function at rule-creation time):

1. Create the rule (via the Cumulus API), with the `state` property set to
   either `"DISABLED"` or `"ENABLED"` (the value doesn't matter because of the
   Cumulus bug described above).  For example:

   ```json
   {
     "name": "my_rule",
     "state": "DISABLED",
     "rule": {
       "type": "onetime"
     },
     "workflow": "DiscoverAndQueueGranules",
     "provider": "my_provider",
     "collection": "my_collection"
   }
   ```

   When the rule is added, the `"DiscoverAndQueueGranules"` Step Function will
   be triggered, but since the rule's `"meta.rule.state"` value is unspecified,
   the initial Choice step in the Step Function will cause the workflow to exit
   immediately, with no actions performed.

1. Update (replace) the rule (via the Cumulus API), setting the `"state"` value
   to `"ENABLED"`, and also adding the value `"ENABLED"` at the path
   `"meta.rule.state"`:

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
       "rule": {
         "state": "ENABLED",
       }
     }
   }
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
initial execution triggered at rule-creation time).  This is achieved by
updating (replacing) the rule, with `"action"` set to `"rerun"` in the payload.
See the Cumulus API documenation for [updating (replacing) a rule][2].  Note,
however, that due to _another bug_ in Cumulus, the name of the rule must also be
specified in the payload.  For example, the payload for the update must look as
follows:

```json
{
  "name": "my_rule",
  "action": "rerun"
}
```

### Performing a Discovery Dry Run

To aid in debugging of a rule's configuration, or to verify the expected list of
granules from "discovery" only, the `DiscoverAndQueueGranules` workflow also
supports a `"meta.dryRun"` flag (boolean value) to enable or disable a
"dry run".  When a rule's `"meta.dryRun"` flag is set to `true`, the workflow
exits after the "discovery" step, thus avoiding queueing the discovered
granules (and thus avoiding ingestion and publication to the CMR).  When the
flag is missing or explicitly set to `false`, execution proceeds normally
through the remaining steps of the workflow.

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
    "dryRun": true,
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

For example, once `"dryRun"` is added to the `"meta"` section, it cannot simply
be removed to _implicitly_ set `"meta.dryRun"` to `false` (the default value)
because the `"meta.dryRun"` value will _not_ be removed from the database.
Instead, you must now _explicitly_ set the value to `false` to _disable_
"dry run" mode:

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
    "dryRun": false,
    "rule": {
      "state": "ENABLED",
    }
  }
}
```

[1]: https://nasa.github.io/cumulus/docs/v9.3.0/data-cookbooks/setup#rules
[2]: https://nasa.github.io/cumulus-api/#updatereplace-rule
