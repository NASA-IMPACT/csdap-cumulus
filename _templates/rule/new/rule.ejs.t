---
to: app/stacks/cumulus/resources/rules/<%= collectionName %>/v<%= collectionVersion %>/<%= collectionName %>___<%= collectionVersion %>_<%= year %>.json
message: >
  hygen rule new
  --provider <%= provider %>
  --collection-name <%= collectionName %>
  --collection-version <%= collectionVersion %>
  --provider-path-format "<%- providerPathFormat %>"
  --year <%= year %>
---
{
  "name": "<%= collectionName %>___<%= collectionVersion %>_<%= year %>",
  "state": "DISABLED",
  "rule": {
    "type": "onetime"
  },
  "provider": "<%= provider %>",
  "collection": {
    "name": "<%= collectionName %>",
    "version": "<%= collectionVersion %>"
  },
  "workflow": "DiscoverAndQueueGranules",
  "meta": {
    "discoverOnly": false,
    "providerPathFormat": "<%- providerPathFormat %>",
    "rule": {
      "state": "DISABLED"
    },
    "startDate": "<%= year %>-01-01T00:00:00Z",
    "endDate": "<%= parseInt(year) + 1 %>-01-01T00:00:00Z",
    "step": "P1D"
  }
}

