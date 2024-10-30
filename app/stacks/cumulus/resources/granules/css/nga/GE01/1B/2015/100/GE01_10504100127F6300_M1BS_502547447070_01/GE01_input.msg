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
        "execution_name": "143a2212-f994-46e9-a9dd-7cd166bfb729",
        "message_source": "sfn",
        "queueExecutionLimits": {
          "https://sqs.us-west-2.amazonaws.com/772632177894/cumulus-jayanthi-cba-backgroundJobQueue": 1400,
          "https://sqs.us-west-2.amazonaws.com/772632177894/cumulus-jayanthi-cba-backgroundProcessing": 5
        },
        "state_machine": "arn:aws:states:us-west-2:772632177894:stateMachine:cumulus-jayanthi-cba-IngestAndPublishGranule",
        "system_bucket": "csda-cumulus-jayanthi-cba-internal-7894",
        "workflow_start_time": 1719352566308,
        "parentExecutionArn": "arn:aws:states:us-west-2:772632177894:execution:cumulus-jayanthi-cba-DiscoverAndQueueGranules:ab09bf16-16aa-44e5-9aaa-8ee51d1a6d54",
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
          "createdAt": 1719338489463,
          "updatedAt": 1719338489463,
          "name": "GE01_Pan_L1B",
          "version": "1",
          "url_path": "{cmrMetadata.CollectionReference.ShortName}___{cmrMetadata.CollectionReference.Version}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, YYYY)}/{dateFormat(cmrMetadata.TemporalExtent.SingleDateTime, DDDD)}/{cmrMetadata.GranuleUR}",
          "duplicateHandling": "skip",
          "granuleId": ".*",
          "granuleIdExtraction": "^(GE01_.+-P1BS-.+_P\\d{3}).+$",
          "files": [
            {
              "type": "browse",
              "regex": ".*-thumb[.]jpg$",
              "bucket": "public",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg"
            },
            {
              "type": "data",
              "regex": ".*-BROWSE[.]jpg$",
              "bucket": "protected",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg"
            },
            {
              "type": "metadata",
              "regex": ".*-cmr[.]json$",
              "bucket": "protected",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json"
            },
            {
              "type": "data",
              "regex": ".*[.]tar$",
              "bucket": "protected",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar"
            },
            {
              "type": "data",
              "regex": ".*[.]ntf$",
              "bucket": "protected",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf"
            },
            {
              "type": "data",
              "regex": ".*[.]xml$",
              "bucket": "protected",
              "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml"
            }
          ],
          "sampleFileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
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
          "updatedAt": 1719338477683
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
            "granuleId": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001",
            "dataType": "GE01_Pan_L1B",
            "version": "1",
            "provider": "maxar",
            "files": [
              {
                "size": 151551,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "efbce95142213d20e621459babe69dc0c1da013e44a221eaec7f6b231a1ee3e4"
              },
              {
                "size": 7822,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "type": "metadata",
                "checksumType": "md5",
                "checksum": "f4b8e40bd063c5824a768fa0c402599f"
              },
              {
                "size": 151551,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "type": "browse",
                "checksumType": "md5",
                "checksum": "0195c66d9c9f53dd6570951bbfef1912"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "ef7abfa1c027912344361a0de2634d858955e397ca560dfb5406aec92b99e7f7"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "58a36c78f7acbe2f6c8f093226c7c7f4330d12c7b93d7a61c64bed316c705a14"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "file-staging/cumulus-jayanthi-cba/GE01_Pan_L1B___1/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "a85806ee0199c337ff575c6bcfc48daf9f9706f36e059af9b9811d69716d5d8d"
              }
            ],
            "sync_granule_duration": 578,
            "createdAt": 1719352573427
          }
        ],
        "process": null,
        "file_etags": {
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json": "\"c1623687eb291960cb27faeda9bf0a17\""
        }
      },
      "payload": {
        "granules": [
          {
            "granuleId": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001",
            "dataType": "GE01_Pan_L1B",
            "version": "1",
            "provider": "maxar",
            "files": [
              {
                "size": 151551,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "efbce95142213d20e621459babe69dc0c1da013e44a221eaec7f6b231a1ee3e4"
              },
              {
                "size": 151551,
                "bucket": "csda-cumulus-jayanthi-cba-public-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
                "type": "browse",
                "checksumType": "md5",
                "checksum": "0195c66d9c9f53dd6570951bbfef1912"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "ef7abfa1c027912344361a0de2634d858955e397ca560dfb5406aec92b99e7f7"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "58a36c78f7acbe2f6c8f093226c7c7f4330d12c7b93d7a61c64bed316c705a14"
              },
              {
                "size": 15,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
                "type": "data",
                "checksumType": "SHA-256",
                "checksum": "a85806ee0199c337ff575c6bcfc48daf9f9706f36e059af9b9811d69716d5d8d"
              },
              {
                "size": 7822,
                "bucket": "csda-cumulus-jayanthi-cba-protected-7894",
                "key": "GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "source": "css/nga/GE01/1B/2022/102/GE01_105001002B1B4700_P1BS_507956386020_01/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "fileName": "GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json",
                "type": "metadata",
                "checksumType": "md5",
                "checksum": "f4b8e40bd063c5824a768fa0c402599f"
              }
            ],
            "sync_granule_duration": 578,
            "createdAt": 1719352573427
          }
        ],
        "copied_to_orca": [
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-BROWSE.jpg",
          "s3://csda-cumulus-jayanthi-cba-public-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-thumb.jpg",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.ntf",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.tar",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001.xml",
          "s3://csda-cumulus-jayanthi-cba-protected-7894/GE01_Pan_L1B___1/2022/102/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001/GE01_20220412012140_105001002B1B4700_22APR12012140-P1BS-507956386020_01_P001-cmr.json"
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
