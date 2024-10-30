{
  "cma": {
    "ReplaceConfig": {
      "MaxSize": 16384,
      "Path": "$.payload",
      "TargetPath": "$.payload"
    },
    "task_config": {
      "bucket": "{$.meta.buckets.internal.name}",
      "stack": "{$.meta.stack}",
      "cmr": "{$.meta.cmr}",
      "launchpad": "{$.meta.launchpad}",
      "etags": "{$.meta.file_etags}"
    },
    "event": {
      "cumulus_meta": {
        "cumulus_version": "18.2.0",
        "execution_name": "d2dc4432-28a2-4044-8dd7-4dcbb765c3fd",
        "message_source": "sfn",
        "queueExecutionLimits": {
          "https://sqs.us-west-2.amazonaws.com/772632177894/cumulus-jayanthi-cba-backgroundJobQueue": 1400,
          "https://sqs.us-west-2.amazonaws.com/772632177894/cumulus-jayanthi-cba-backgroundProcessing": 5
        },
        "state_machine": "arn:aws:states:us-west-2:772632177894:stateMachine:cumulus-jayanthi-cba-IngestAndPublishGranule",
        "system_bucket": "csda-cumulus-jayanthi-cba-internal-7894",
        "workflow_start_time": 1716945726188,
        "parentExecutionArn": "arn:aws:states:us-west-2:772632177894:execution:cumulus-jayanthi-cba-DiscoverAndQueueGranules:7c9d6b50-c8cf-4631-ab78-6b707e1509a0",
        "queueUrl": "https://sqs.us-west-2.amazonaws.com/772632177894/cumulus-jayanthi-cba-backgroundJobQueue"
      },
      "exception": "None",
      "meta": {
        "buckets": {
          "dashboard": {
            "name": "csda-cumulus-jayanthi-cba-dashboard-7894",
            "type": "dashboard"
          },
          "internal": {
            "name": "csda-cumulus-jayanthi-cba-internal-7894",
            "type": "internal"
          },
          "orca_default": {
            "name": "csda-cumulus-cba-uat-orca-archive",
            "type": "orca"
          },
          "orca_reports": {
            "name": "csda-cumulus-cba-uat-orca-reports",
            "type": "orca"
          },
          "private": {
            "name": "csda-cumulus-jayanthi-cba-private-7894",
            "type": "private"
          },
          "protected": {
            "name": "csda-cumulus-jayanthi-cba-protected-7894",
            "type": "protected"
          },
          "provider": {
            "name": "csda-cumulus-jayanthi-cba-provider-7894",
            "type": "provider"
          },
          "public": {
            "name": "csda-cumulus-jayanthi-cba-public-7894",
            "type": "public"
          }
        },
        "cmr": {
          "clientId": "csdap-cumulus-jayanthi-cba",
          "cmrEnvironment": "UAT",
          "cmrLimit": 100,
          "cmrPageSize": 50,
          "oauthProvider": "launchpad",
          "passwordSecretName": "",
          "provider": "CSDA",
          "username": ""
        },
        "collection": {
          "createdAt": 1716903832729,
          "updatedAt": 1716913873234,
          "name": "WV02_Pan_L1B",
          "version": "1",
          "url_path": "{cmrMetadata.CollectionReference.ShortName}___{cmrMetadata.CollectionReference.Version}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, YYYY)}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, DDDD)}/{cmrMetadata.GranuleUR}",
          "duplicateHandling": "skip",
          "granuleId": ".*",
          "granuleIdExtraction": "^(WV02_.+-P1BS-.+_P\\d{3}).+(?<!rename)$",
          "files": [
            {
              "type": "browse",
              "regex": "^(WV02_.+_P\\d{3})-thumb[.]jpg$",
              "bucket": "public",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg"
            },
            {
              "type": "data",
              "regex": "^(WV02_.+_P\\d{3})-BROWSE[.]jpg$",
              "bucket": "protected",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg"
            },
            {
              "type": "metadata",
              "regex": "^(WV02_.+_P\\d{3})-cmr[.]json$",
              "bucket": "protected",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json"
            },
            {
              "type": "data",
              "regex": "^(WV02_.+_P\\d{3})[.]tar$",
              "bucket": "protected",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar"
            },
            {
              "type": "data",
              "regex": "^(WV02_.+_P\\d{3})[.]ntf$",
              "bucket": "protected",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf"
            },
            {
              "type": "data",
              "regex": "^(WV02_.+_P\\d{3})[.]xml$",
              "bucket": "protected",
              "reportToEms": true,
              "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml"
            }
          ],
          "sampleFileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
          "ignoreFilesConfigForDiscovery": false,
          "meta": {
            "preferredQueueBatchSize": 1
          }
        },
        "distribution_endpoint": "https://bamacwjvsb.execute-api.us-west-2.amazonaws.com/dev/",
        "launchpad": {
          "api": "https://api.launchpad.nasa.gov/icam/api/sm/v1",
          "certificate": "launchpad.pfx",
          "passphraseSecretName": "cumulus-jayanthi-cba-message-template-launchpad-passphrase20230224230525645100000003"
        },
        "provider": {
          "id": "maxar",
          "host": "csda-cumulus-jayanthi-cba-provider-7894",
          "protocol": "s3",
          "createdAt": 1677683318446,
          "updatedAt": 1716913832667
        },
        "stack": "cumulus-jayanthi-cba",
        "template": "s3://csda-cumulus-jayanthi-cba-internal-7894/cumulus-jayanthi-cba/workflow_template.json",
        "workflow_name": "IngestAndPublishGranule",
        "workflow_tasks": {
          "0": {
            "name": "cumulus-jayanthi-cba-RequireCmrFiles",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-RequireCmrFiles"
          },
          "1": {
            "name": "cumulus-jayanthi-cba-SyncGranule",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-SyncGranule"
          },
          "2": {
            "name": "cumulus-jayanthi-cba-AddUmmgChecksums",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-AddUmmgChecksums"
          },
          "3": {
            "name": "cumulus-jayanthi-cba-AddMissingFileChecksums",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-AddMissingFileChecksums"
          },
          "4": {
            "name": "cumulus-jayanthi-cba-MoveGranules",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-MoveGranules"
          },
          "5": {
            "name": "cumulus-jayanthi-cba-UpdateGranulesCmrMetadataFileLinks",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-UpdateGranulesCmrMetadataFileLinks"
          },
          "6": {
            "name": "cumulus-jayanthi-cba-OrcaCopyToArchiveAdapter",
            "version": "$LATEST",
            "arn": "arn:aws:lambda:us-west-2:772632177894:function:cumulus-jayanthi-cba-OrcaCopyToArchiveAdapter"
          }
        },
        "input_granules": [
          {
            "granuleId": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001",
            "dataType": "WV02_Pan_L1B",
            "version": "1",
            "provider": "maxar",
            "files": [
              {
                "size": 138465,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "bf76a48e5e0771d7333997f3271494a47b91dacba1d9b0ada3d57b3f53c6f6fb"
              },
              {
                "size": 7817,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "type": "metadata",
                "checksumType": "md5",
                "checksum": "66fad3b9b6d5bb054bc8853e0710a9ff"
              },
              {
                "size": 138465,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "type": "browse",
                "checksumType": "md5",
                "checksum": "99e37b3027034473afe4dd7c13466167"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "edab6a996c4a781ab3c7fbdd7b0475d841ca613f9ddf0d7a4461d6fc7570c63e"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "ba008c0f42eaec0e5a2147602981b7862c9757b63c46db1ef131401004850938"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/WV02_Pan_L1B___1/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "87725fa09740166a93ab3d390467fb1ad5cabf05ffa8c104bddb62458e5eec26"
              }
            ],
            "sync_granule_duration": 638,
            "createdAt": 1716945733486
          }
        ],
        "process": null,
        "file_etags": {
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json": "\"57cc86792c3044c21d3f44bc06cb729e\""
        }
      },
      "payload": {
        "granules": [
          {
            "granuleId": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001",
            "dataType": "WV02_Pan_L1B",
            "version": "1",
            "provider": "maxar",
            "files": [
              {
                "size": 138465,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "bf76a48e5e0771d7333997f3271494a47b91dacba1d9b0ada3d57b3f53c6f6fb"
              },
              {
                "size": 138465,
                "bucket": "csda-cumulus-jayanthi-cba-public-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
                "type": "browse",
                "checksumType": "md5",
                "checksum": "99e37b3027034473afe4dd7c13466167"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "edab6a996c4a781ab3c7fbdd7b0475d841ca613f9ddf0d7a4461d6fc7570c63e"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "ba008c0f42eaec0e5a2147602981b7862c9757b63c46db1ef131401004850938"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "87725fa09740166a93ab3d390467fb1ad5cabf05ffa8c104bddb62458e5eec26"
              },
              {
                "size": 7817,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "source": "css/nga/WV02/1B/2009/322/WV02_103001000286DF00_P1BS_052385675010_01/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "fileName": "WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json",
                "type": "metadata",
                "checksumType": "md5",
                "checksum": "66fad3b9b6d5bb054bc8853e0710a9ff"
              }
            ],
            "sync_granule_duration": 638,
            "createdAt": 1716945733486
          }
        ],
        "copied_to_orca": [
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-BROWSE.jpg",
          "s3://csda-cumulus-jayanthi-cba-public-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-thumb.jpg",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.ntf",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.tar",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001.xml",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/WV02_Pan_L1B___1/2009/322/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001/WV02_20091118021009_103001000286DF00_09NOV18021009-P1BS-052385675010_01_P001-cmr.json"
        ]
      },
      "task_config": {
        "s3MultipartChunksizeMb": "{$.meta.collection.meta.s3MultipartChunksizeMb}",
        "excludedFileExtensions": "{$.meta.collection.meta.orca.excludedFileExtensions}",
        "providerId": "{$.meta.provider.id}",
        "providerName": "{$.meta.provider.name}",
        "executionId": "{$.cumulus_meta.execution_name}",
        "collectionShortname": "{$.meta.collection.name}",
        "collectionVersion": "{$.meta.collection.version}",
        "defaultBucketOverride": "{$.meta.collection.meta.orca.defaultBucketOverride}"
      }
    }
  }
}
