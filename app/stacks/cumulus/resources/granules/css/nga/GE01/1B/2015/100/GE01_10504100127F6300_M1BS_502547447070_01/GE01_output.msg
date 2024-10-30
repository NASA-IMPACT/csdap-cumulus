{
  "errorType": "Error",
  "errorMessage": "Failed to ingest, statusCode: 422, statusMessage: Unprocessable Entity, CMR error message: [\"Collection with Short Name [GE01_Pan_L1B], Version Id [1] referenced in granule [GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001] provider [CSDA] does not exist.\"]",
  "trace": [
    "Error: Failed to ingest, statusCode: 422, statusMessage: Unprocessable Entity, CMR error message: [\"Collection with Short Name [GE01_Pan_L1B], Version Id [1] referenced in granule [GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001] provider [CSDA] does not exist.\"]",
    "    at CMR.ingestUMMGranule (/var/task/webpack:/src/CMR.ts:259:13)",
    "    at processTicksAndRejections (node:internal/process/task_queues:96:5)",
    "    at publishUMMGJSON2CMR (/var/task/webpack:/src/cmr-utils.js:184:15)",
    "    at publish2CMR (/var/task/webpack:/src/cmr-utils.js:230:12)",
    "    at async Promise.all (index 0)",
    "    at postToCMR (/var/task/webpack:/index.js:131:19)",
    "    at Object.runCumulusTask (/var/task/webpack:/node_modules/@cumulus/cumulus-message-adapter-js/dist/cma.js:221:1)",
    "    at Runtime.handler (/var/task/webpack:/index.js:159:10)"
  ]
}
