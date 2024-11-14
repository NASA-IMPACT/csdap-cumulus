import boto3
import csv
import io
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.setLevel(logging.DEBUG)
logging.basicConfig(
    filename="app.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
)


def delete_records(bucket_name, file_name, table_name):

    # Read the CSV file from the S3 bucket
    s3 = boto3.client("s3")
    csv_file_obj = s3.get_object(Bucket=bucket_name, Key=file_name)
    csv_content = csv_file_obj["Body"].read().decode("utf-8")

    # Read the CSV data
    csv_reader = csv.DictReader(io.StringIO(csv_content))

    # Specify your DynamoDB  primary key
    primary_key_name = "key"  #

    # List to store delete requests
    delete_requests = []

    # Process each row in the CSV and prepare delete requests
    for row in csv_reader:
        primary_key_value = row[primary_key_name]
        # print(primary_key_value)

        pkey = {"file_path": primary_key_value}
        # Add delete request to the list
        delete_requests.append({"DeleteRequest": {"Key": pkey}})
        # print(delete_requests)
    # Batch write to DynamoDB to delete the items
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)
    try:
        with table.batch_writer() as batch:
            for delete_request in delete_requests:
                print(delete_request)

                batch.delete_item(**delete_request["DeleteRequest"])

        logger.info(
            f"Successfully processed {len(delete_requests)} records for deletion."
        )
        return {
            "statusCode": 200,
            "body": f"Successfully deleted {len(delete_requests)} records from DynamoDB.",
        }

    except Exception as e:
        logger.error(f"Error deleting records: {str(e)}")
        print("no such record")
        return {"statusCode": 500, "body": f"Error deleting records: {str(e)}"}


file_name = "records_todelete_from_DB.csv"  # List of records to be deleted (primary_keys) from DynamoDB
bucket_name = "jayanthi-for-li"  # bucket name of the above file
table_name = "WV02_sha256_store"  # DynamoDB table name for record deletion
delete_records(bucket_name, file_name, table_name)
