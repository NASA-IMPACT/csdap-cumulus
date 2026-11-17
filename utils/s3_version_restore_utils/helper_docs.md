# Helper Docs helper_docs.md

Last Update: 2026_NOV_17


## How to 'discover' a delete marker using the report

There exists an auto reporting mechanism that reads manifests of the files.
These manifests have both csv and parquet outputs.
These can be searched with AWS Athena.
In order to search them, an AWS Athena 'database' needs to be setup.
Once setup, the two most useful commands are to get the count of current delete markers, and then select some of the current delete markers.
If there are more than 100 delete markers, the query should be modified to be paged until all of it is exhausted.

Before running any queries, an S3 location for query results needs to be configured in side of AWS Athena.

Future Note: We should work on automating these queries and even storing the state in a database, so we can have an automated restore all functionality setup

### Athena Query 1 - Setting up the database (example query for UAT)

Setup
This only needs to be run once per environment. 
```
// CREATE TABLE (UAT Example - UNFILTERED)

CREATE EXTERNAL TABLE uat_csda_all_inventory_unfiltered (
    bucket string,
    key string,
    version_id string,
    is_latest boolean,
    is_delete_marker boolean,
    last_modified_date timestamp,
    object_lock_retain_until_date timestamp,
    object_lock_mode string,
    dt string
)
ROW FORMAT SERDE  
'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
WITH SERDEPROPERTIES (  
'parquet.ignore.statistics'='true')
STORED AS PARQUET
LOCATION 's3://objlock-<account_number>-us-west-2-auto-extend-objlock-f1smyy4/ngap-ncdp-inventory-report/csda-cumulus-uat-protected-1686/ngap-ncdp-inventory-report-parquet/data/';
```

Operations
Run this query to get the count of how many current flags there are.
(Note: Previously restored delete flags may still show up in this count)
```
// Count most recent delete markers, with Unique Keys
WITH uat_csda_all_inventory_unfiltered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "key"
            ORDER BY last_modified_date DESC
        ) AS row_num
    FROM uat_csda_all_inventory_unfiltered
)
SELECT COUNT(*) AS object_count
FROM uat_csda_all_inventory_unfiltered
WHERE row_num = 1 AND is_delete_marker = true AND is_latest = true AND "Key" NOT LIKE 'file-staging/%' AND "Key" NOT LIKE 'lock/%'

```

Operations
Run this query to get the list of keys and version ids for delete flags that can be restored
(Note: After one of these flags are restored, you may encounter it again, so you may need to filter out for more recent keys that have already been restored, this is why we could benefit from having a database which tracks the restores, so we can use that timeline trail to figure out which ones were deleted multiple times and restored.)
When using the restore scripts below, if you pass in a delete flag that has already been restored, it will not fail, it will just pass right through.  The script will not break.  There will simply be no effect.
IMPORTANT: This query will almost certainly return a number of rows that is either equal to or less than the count query above.
```
// Select 100 most recent delete markers, with Unique Keys
WITH uat_csda_all_inventory_unfiltered AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "key"
            ORDER BY last_modified_date DESC
        ) AS row_num
    FROM uat_csda_all_inventory_unfiltered
)
SELECT *
FROM uat_csda_all_inventory_unfiltered
WHERE row_num = 1 AND is_delete_marker = true AND is_latest = true AND "Key" NOT LIKE 'file-staging/%' AND "Key" NOT LIKE 'lock/%'
ORDER BY last_modified_date DESC
LIMIT 100;

```

## How to use the scripts to restore deleted granules

Notes:
To restore files (S3 objects), you must do the following
- Acquire the Delete Markers for the files you want to restore.
- Have a matching key path for each of the delete markers you have.
- Run the commands.

Variables that appear below
$BUCKET 	  // (Required) This is your bucket name
$KEY_PATH 	  // (Required for most cost effective operations) This is the path to the original filename.
$PREFIX  	  // This is also a key path, but it is only a partial path to the file or directory you are trying to restore.  This is useful during discovery of Delete Markers and pretty much only during testing.
$VERSION_ID   // (Required for most cost effective operations) This is the version id of the DELETE MARKER, not the file itself, but it's delete marker.  This only exists if a file has been deleted while S3 versioning is on and we are still within the 30 day purging window.
$AWS_PROOFILE // (Required) This links your AWS Cli command to your environment. aws --profile parameter.



Inputs for restoring at scale
Format of the expected JSON input for restoring a file
```
{
  "bucket": "$BUCKET",
  "objects": [
    {
      "key": "$KEY_PATH",
      "version_id": "$VERSION_ID"
    },
    {
      // Another Object
    },
    {
      // Another Object etc
    }
  ]
}
```


Full UAT Example

Input File
```
{
  "bucket": "csda-cumulus-uat-protected-1686",
  "objects": [
    {
      "key": "planet/PSScene3Band/20171201_031958_0f31_1B_Analytic_metadata.xml",
      "version_id": "fyxbQDhJ1EKyP3vy8bRL7.aV1XgZ4iuK"
    },
    {
      "key": "planet/PSScene3Band/20171201_031958_0f31_1B_Analytic_DN.tif",
      "version_id": "udd9L7jYdk2LOgPVaoWTbZAWG4ZSwpr6"
    },
    {
      "key": "planet/PSScene3Band/20171201_031958_0f31_1B_Analytic_DN_udm.tif",
      "version_id": "knlTeenNPWADvIaUYUdk8qrJFuwWPhzR"
    }
  ]
}

```

```
// Running the Command on the terminal command line:
sh restore-delete-markers.sh example_input_UAT.json csda-cumulus-uat-1686

// EXPECTED OUTPUT:

Bucket: csda-cumulus-uat-protected-1686
Objects to restore: 3

Processing batch:
  Offset : 0
  Count  : 3
Batch Results:
  Restored                : 3
  Already Restored        : 0
  Other Errors            : 0


==============================================
RESTORE SUMMARY
==============================================

Successfully Restored : 3
Already Restored      : 0
Other Errors          : 0

Restore process complete.

```


## How to 'discover' delete markers without using the reports (Kind of a search and query AWS CLI Approach)

Usecase and Commands Reference

Use Case: You need the Delete Markers and Paths
Consult the Aethena reports for this information.

Use Case: You have the delete marker (Version id) and path, and you want to restore it.
aws --no-cli-pager s3api delete-object --bucket "$BUCKET" --key "$KEY_PATH" --version-id "$VERSION_ID" --profile "$PROFILE"

Use Case: You have a delete marker (from another source like the Aethena reports) and nearly an exact address (perhaps you just know the path up to the directory level) and you need to verify the marker
Use Case: You do not have the delete markers, but you know what subdirectory (prefix) where there may be deleted files that have markers you need.
This command gets you a list of delete markers under a specified prefix.
IMPORTANT - Make sure the prefix you use has only a small number of objects below it because this command walks all of them.  This could be an expensive command if run on an entire bucket
`aws --no-cli-pager s3api list-object-versions --bucket "$BUCKET" --prefix "$PREFIX" --profile "$PROFILE" --query 'DeleteMarkers[*].[Key,VersionId,IsLatest]' --output table`


// TESTING ENVIRONMENTS ONLY
Use Case:  You do not have the delete markers, but you do not know what subdirectory (prefix) where there may be deleted files that have markers you need.
WARNING - This command examines the entire bucket passed into it
WARNING - Expensive command
WARNING - Do not Use this except during Testing (Sandbox and UAT) and ONLY for buckets that are small enough to absorb this command.
If you need to get the lists for ALL delete markers (note if there are a large number of objects, this could be an expensive call and may not function properly)
`aws --no-cli-pager s3api list-object-versions --bucket "$BUCKET_NAME" --profile "$AWS_PROFILE" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output table`




