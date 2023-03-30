---
to: app/stacks/cumulus/resources/rules/<%= dataset_name || 'DSNAME' %>/<%= dataset_name || 'DSNAME' %>___<%= version_str || '1' %>_<%= start_date_YYYY %>.json
---
{
  "name": "<%= dataset_name || 'DSNAME' %>___<%= version_str || '1' %>_<%= start_date_YYYY %>",
  "state": "DISABLED",
  "rule": {
    "type": "onetime"
  },
  "provider": "maxar",
  "collection": {
    "name": "<%= dataset_name || 'DSNAME' %>",
    "version": "1"
  },
  "workflow": "DiscoverAndQueueGranules",
  "meta": {
    "discoverOnly": false,
    "providerPathFormat": "<%= provider_path_format %>",
    "rule": {
      "state": "DISABLED"
    },
    "startDate": "<%= start_date_YYYY %>-01-01T00:00:00Z",
    "endDate": "<%= (start_date_YYYY + 1) %>-01-01T00:00:00Z",
    "step": "P1D"
  }
}


