# Scalable Granule Discovery

## Motivation

Out of the box, **Cumulus inadvertenly limits the volume of files that can be
discovered during a single execution of granule discovery** because it employs a
naive implementation that assumes the entire list of discovered files will fit
into memory.  Clearly, if the list of files is too large, the discovery step of
the workflow will run **out of memory**, and the workflow will crash.

It is also possible for the discovery step to **timeout**, which can occur when
the list of discovered files is large, but not quite large enough to exceed
available memory.  In this case, it might not be able to list and queue all of
the discovered granules before a timeout occurs.

One solution to these time and space constraints is to move the discovery step
from a Lambda Function to an EC2 Task, which does allow for more memory and
time, but which simply kicks the proverbial can down the road.  At some point,
it is still possible to exceed these expanded limitations.

While these problems are generally unlikely to occur in the course of forward
processing, they are very likely to occur during historical processing of large
data sets.

## Illustration

To illustrate the problem, suppose we have granule files in an S3 Bucket named
`planet-bucket`, and that the following is a sample of these files, showing the
files for a single granule in the collection (paths abridged):

```plain
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_1B_Analytic.tif
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_1B_Analytic_RPC.TXT
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_1B_Analytic_metadata.xml
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_1B_Analytic_DN_udm.tif
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_cmr.json
path/to/PSScene3Band-20171215_154051_0f31/.../20171215_154051_0f31_metadata.json
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_1B_Analytic.tif
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_1B_Analytic_RPC.TXT
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_1B_Analytic_metadata.xml
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_1B_Analytic_DN_udm.tif
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_cmr.json
path/to/PSScene3Band-20171215_154052_0f31/.../20171215_154052_0f31_metadata.json
```

In order to discover (and subsequently ingest) _all_ of the (historical) files
in the collection, we must define a _provider_, like so:

```json
{
  "id": "planet",
  "protocol": "s3",
  "host": "planet-bucket"
}
```

In addition, we must define an appropriate _rule_:

```json
{
  "name": "PSScene3Band___1",
  "state": "ENABLED",
  "provider": "planet",
  "collection": {
    "name": "PSScene3Band",
    "version": "1"
  },
  "workflow": "DiscoverAndQueueGranules",
  "rule": {
    "type": "onetime"
  },
  "meta": {
    "providerPath": "path/to/PSScene3Band",
  }
}
```

Given the provider and rule definitions above, running the rule would cause the
following to occur:

1. Trigger the `DiscoverAndQueueGranules` workflow (AWS Step Function)
1. List all files with S3 URIs that have a _prefix_ of
   `s3://planet-bucket/path/to/PSScene3Band`
1. Group files by granule
1. Queue message for each granule (with its list of associated files)
1. Trigger `IngestAndPublishGranule` workflow for each queued message

where:

- The **workflow** (`DiscoverAndQueueGranules`) is specified by the `"workflow"`
  property in the rule definition above
- The **S3 URI prefix** is constructed using the format
  `s3://PROVIDER_HOST/PROVIDER_PATH`, where `PROVIDER_HOST` is the value of the
  `"host"` property in the provider definition, and `PROVIDER_PATH` is the value
  of the `"meta.providerPath"` property in the rule definition

In this example, the discovery step will attempt to discover _all_ granules in
the `PSScene3Band` collection (version `1`) _at once_.  For relatively small
collections (very roughly no more than 500K files), this generally works without
issue, but for larger collections, attempting to list _all_ files in the
collection in memory at once will cause an "out of memory" error (or possibly
cause a timeout, while queuing messages for granule ingestion/publication).

## Solution

Although, for large enough collections, we cannot successfully discover _all_
granules in a collection in a _single_ discovery step, we can divide the files
into groups such that each group is small enough to be discovered separately
from one another.

Notice that the date (`20171215`, in our example above) is included in all of
the file paths.  This means that we can be more precise with the value of
`"meta.providerPath"` specified in our rule.  For example, we could limit
discovery to the single year 2017 by setting `"meta.providerPath"` to
`"path/to/planet/PSScene3Band-2017"`, or even limit it to the single month
December 2017 by setting it to `"path/to/planet/PSScene3Band-201712"`.

By specifying a more precise value for `"meta.providerPath"`, we can avoid
hitting our time and space constraints because a more precise value will result
in a smaller list of files during discovery.  However, for large collections,
the manual effort required to discover each group of granules would be
laborious, pains-taking, and error-prone.

Therefore, we have implemented a relatively simple solution that _automates_
both the creation of more precise `"meta.providerPath"` values (as described
above), as well as the advancing of these values over sequential date ranges.
This enables discovering a practically unlimited number of files without memory
limitations and with a timeout that can be extended to as long a 1 year, which
is the limit for Step Functions.

To enable this automation, this solution adds support for the following new
properties within a rule's `"meta"` section (see farther below for an
explanation of how they're used):

- `"providerPathFormat"`: a date format used in combination with `"startDate"`
  to dynamically generate a value for `"providerPath"` (this format must adhere
  to the [Day.js Format specification])
- `"startDate"`: the UTC start date for discovery, in [ISO 8601] format
- `"endDate"` (optional): the UTC end date for discovery, also in ISO 8601 format
- `"step"` (optional): an [ISO 8601 Duration] to limit the number of granules
  discovered at once

The general algorithm for achieving this automatic, incremental discovery is as
follows:

1. If `"endDate"` is not specified, set it to the current date/time.
1. Format the `"startDate"` using the `"providerPathFormat"` as the date format
   to generate the value for `"providerPath"`.
1. Discover and queue granules with a path that starts with the value of
   `"providerPath"`.  Normally, this would be the last step of the workflow.
1. If `"step"` is specified, generate a new value for `"startDate"` by adding
   `"step"` to the current `"startDate"`.  Otherwise, set the new `"startDate"`
   to the `"endDate"`.
1. If the new `"startDate"` is less than the `"endDate"`, go to step 2;
   otherwise end the workflow.  Note that the end date must be _strictly_ less
   than the end date because the end date is _excluded_ from the range for
   discovery (akin to how a `range` in Python _excludes_ the end value of the
   range).

Returning to our example from above, we can now discover _all_ granules in our
collection, without hitting our time and space constraints, by simply changing
the `"meta"` properties in our rule definition, as follows:

```json
"meta": {
  "providerPathFormat": "'path/to/PSScene3Band-'yyyyMM",
  "startDate": "2016-01",
  "step": "P1M"
}
```

Based on the algorithm outlined above, running our rule with these property
changes will perform the following steps:

1. `"endDate"` is not specified, so it is set to the current date/time.
1. Format the `"startDate"` (`"2016-01"`) using the format
   `"'path/to/PSScene3Band-'yyyyMM"` to generate
   `"path/to/PSScene3Band-201601"` as the value of `"providerPath"`.
1. Discover and queue all granules generated in January 2016 (as dictated by
   the value of `"providerPath"` from the previous step).
1. Add 1 month (a duration of `"P1M"` specified by `"step"`) to `"startDate"` to
   obtain a new `"startDate"` value of `"2016-02"` (more specifically,
   `"2016-02-01T00:00:00Z"`).
1. Format the date `"2016-02-01T00:00:00Z"` using the format
   `"'path/to/PSScene3Band-'yyyyMM"` to generate
   `"path/to/PSScene3Band-201602"` as the value of `"providerPath"`.
1. Discover and queue all granules generated in February 2016 (as dictated by
   the value of `"providerPath"` from the previous step).
1. Add 1 month (a duration of `"P1M"` specified by `"step"`) to `"startDate"` to
   obtain a new `"startDate"` value of `"2016-03"` (more specifically,
   `"2016-03-01T00:00:00Z"`).
1. ...and so on, until `"startDate"` reaches or exceeds `"endDate"`.

In other words, with the `"meta"` changes above, we can ingest _all_ of the
granules in the collection, one month at a time, in a single execution of the
`DiscoverAndQueueGranules` workflow, without running out of memory or time
(assuming we can do so within a year, the maximum timeout for a Step Function).

The relevant source code files are as follows:

- `app/stacks/cumulus/templates/discover-granules-workflow.asl.json`: template
  file defining the Step Function that implements this algorithm
- `app/stacks/cumulus/main.tf`: contains `module "discover_granules_workflow"`
  that references the Step Function template file above
- `src/lib/discovery.ts`: contains the Lambda Functions that implement the logic
  to generate the `"providerPath"` and advance the `"startDate"`

[Day.js Format specification]:
  https://day.js.org/docs/en/display/format
[ISO 8601]:
  https://en.wikipedia.org/wiki/ISO_8601
[ISO 8601 Duration]:
  https://en.wikipedia.org/wiki/ISO_8601#Durations
