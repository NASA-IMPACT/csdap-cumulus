---
to: "app/stacks/cumulus/resources/rules/<%= collectionName %>/v<%= collectionVersion %>/<%= collectionName %>___<%= collectionVersion %>_CNM.json"
message: >
  hygen cnm-rule new
  --provider <%= provider %>
  --collection-name <%= collectionName %>
  --collection-version <%= collectionVersion %>
---
{
  "name": "<%= collectionName %>___<%= collectionVersion %>_CNM",
  "state": "ENABLED",
  "workflow": "CNMIngestAndPublishGranule",
  "provider": "<%= provider %>",
  "collection": {
    "name": "<%= collectionName %>",
    "version": "<%= collectionVersion %>"
  },
  "rule": {
    "type": "sns"
  },
  "meta": {
    "cnmResponseMethod": "sns"
  },
  "tags": [
    "cnm"
  ]
}
