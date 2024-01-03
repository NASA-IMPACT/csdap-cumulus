---
to: "app/stacks/cumulus/resources/rules/<%= collectionName %>/v<%= collectionVersion %>/<%= collectionName %>___<%= collectionVersion %>_<%= startYear == endYear ? startYear : `${startYear}_${endYear}` %>.json"
message: >
  hygen rule new
  --provider <%= provider %>
  --collection-name <%= collectionName %>
  --collection-version <%= collectionVersion %>
  --provider-path-format "<%- providerPathFormat %>"
  --ingested-path-format "<%- ingestedPathFormat %>"
  --start-year <%= startYear %>
  --end-year <%= endYear %>
---
{
  "name": "<%= collectionName %>___<%= collectionVersion %>_<%= startYear == endYear ? startYear : `${startYear}_${endYear}` %>",
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
    "ingestedPathFormat": "<%- ingestedPathFormat %>",
    "startDate": "<%= startYear %>-01-01T00:00:00Z",
    "endDate": "<%= parseInt(endYear) + 1 %>-01-01T00:00:00Z",
    "step": "P1D",
    "maxBatchSize": 200,
  }
}
