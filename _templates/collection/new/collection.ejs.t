---
to: app/stacks/cumulus/resources/collections/<%= collectionName %>___<%= collectionVersion %>.json
message: >
  hygen rule new
  --collection-name <%= collectionName %>
  --collection-version <%= collectionVersion %>
  --sample-filename-prefix <%= sampleFilenamePrefix %>
---
{
  "name": "<%= collectionName %>",
  "version": "<%= collectionVersion %>",
  "duplicateHandling": "replace",
  "granuleId": ".*",
  "granuleIdExtraction": "TBD__EXAMPLE__^(WV02_.+-M1BS-.+_P\\d{3}).+$",
  "sampleFileName": "<%= sampleFilenamePrefix %>-BROWSE.jpg",
  "url_path": "{cmrMetadata.CollectionReference.ShortName}___{cmrMetadata.CollectionReference.Version}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, YYYY)}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, DDD)}/{cmrMetadata.GranuleUR}",
  "meta": {
    "preferredQueueBatchSize": 5
  },
  "ignoreFilesConfigForDiscovery": false,
  "files": [
    {
      "regex": ".*-thumb[.]jpg$",
      "sampleFileName": "<%= sampleFilenamePrefix %>-thumb.jpg",
      "type": "browse",
      "bucket": "public"
    },
    {
      "regex": ".*-BROWSE[.]jpg$",
      "sampleFileName": "<%= sampleFilenamePrefix %>-BROWSE.jpg",
      "type": "data",
      "bucket": "protected"
    },
    {
      "regex": ".*-cmr[.]json$",
      "sampleFileName": "<%= sampleFilenamePrefix %>-cmr.json",
      "type": "metadata",
      "bucket": "protected"
    },
    {
      "regex": ".*[.]tar$",
      "sampleFileName": "<%= sampleFilenamePrefix %>.tar",
      "type": "data",
      "bucket": "protected"
    },
    {
      "regex": ".*[.]ntf$",
      "sampleFileName": "<%= sampleFilenamePrefix %>.ntf",
      "type": "data",
      "bucket": "protected"
    },
    {
      "regex": ".*[.]xml$",
      "sampleFileName": "<%= sampleFilenamePrefix %>.xml",
      "type": "data",
      "bucket": "protected"
    }
  ]
}
