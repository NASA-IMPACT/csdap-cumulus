# step_05__mcp_lambda_to_delete_s3_files__final.py

# step_05__mcp_lambda_to_delete_s3_files.py

# Parse the Path from the input
# 



import time
import random
import json
import boto3
import hashlib
import sys

# Get the needed S3 Boto Client
s3       = boto3.client('s3')

# Setting this to True will create significant output to Cloudwatch Logs
SETTING__IS_OUTPUT_DEBUG_MODE = False #True #False # True # False

# List of all the possible extensions for MAXAR Granules
#SETTINGS__all_extensions_MAXAR = ['-BROWSE.jpg','-cmr.json','-thumb.jpg','.rename','.tar','.tif','.xml']
SETTINGS__all_extensions_MAXAR = ['.ntf']

# When we need to print the output to the logs to see what is going on
def debug_print(str_to_print="", obj_out=None):
    if(SETTING__IS_OUTPUT_DEBUG_MODE == True):
        print(f'{str_to_print}:    {obj_out}')

# Without this, we hit the throtle limits when running the S3 batch operation.
def random_sleep():
    sleep_time = random.uniform(0.01, 0.1)  # Select a random number between 0.01 and 0.10
    debug_print(str_to_print="Sleeping for: " + str(sleep_time) + " seconds.")
    time.sleep(sleep_time)

# I want to verify that we are ONLY deleting files from the correct bucket and ONLY paths that include the expected initial paths.
def validate__is_correct_bucket_and_root_path(input_bucket_name='', input_key_path=''):
    is_safe_to_delete = False
    validation_message = ''

    expected_bucket         = 'csdap-maxar-delivery'
    expected_root_paths     = ['css/nga/WV04/1B/', 'css/nga/WV03/1B/', 'css/nga/WV02/1B/', 'css/nga/WV01/1B/', 'css/nga/GE01/1B/']
    if(input_bucket_name == expected_bucket):
        # Now Check to make sure the first set of characters in the path exactly matches one of the expected root paths.
        if(input_key_path[0:16] in expected_root_paths):
            # At this point, we have passed both validation checks.
            is_safe_to_delete   = True
            validation_message  = ''
        else:
            # Looks like the root path is not one of the tightly controlled, expected paths.  Do not attempt a delete!
            is_safe_to_delete   = False
            validation_message  = '|| Input Key Path has a root path that is not one of the expected paths.  (input_key_path[0:16]): ' + str(input_key_path[0:16]) + ' is not found in the list (expected_root_paths): ' + str(expected_root_paths) + '  '
    else:
        is_safe_to_delete = False
        validation_message += '|| Wrong Bucket Name: (input_bucket_name): ' + str(input_bucket_name) + ' does not equal (expected_bucket): ' + str(expected_bucket) + '  '

    return is_safe_to_delete, validation_message


# Actually delete a file from S3
def execute_s3_delete(bucket_name='', key_path=''):
    # Values to return
    did_delete      = False
    error_message   = ''

    # First Validate that we can delete this file (based on hard coded validation values)
    is_pass_validation, validation_message = validate__is_correct_bucket_and_root_path(input_bucket_name=bucket_name, input_key_path=key_path)

    # Did we pass the Validation?
    if(is_pass_validation == False):
        did_delete      = False
        error_message   = validation_message
    else:
        try:
            #debug_print(str_to_print="execute_s3_delete", obj_out=f'TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): {bucket_name}, (key_path): {key_path}')
            s3.delete_object(Bucket=bucket_name, Key=key_path)
            did_delete      = True
            error_message   = ''
        except:
            did_delete      = False
            err_info        = str(sys.exc_info())
            error_message   = f'failed to delete {key_path}.  Error Message: {err_info}'
        
    # Return the result, If we did delete and any error messages.
    return did_delete, error_message

# This function will process the lists, and 
def execute_process_granule_key_path_list(bucket_name='', list_of_s3_key_paths_to_delete=[], original_key_path='', original_key_path_to_granule='UNSET'):
    file_exts_removed = []
    error_exts = []
    error_messages = []

    # Iterate the entire list
    for full_key_path in list_of_s3_key_paths_to_delete:
        current_extension = full_key_path.split(original_key_path_to_granule)[1]            # Should Convert a Full Keypath back into a string like this:       '-BROWSE.jpg'

        # Attempt to delte the file
        did_delete, error_message = execute_s3_delete(bucket_name=bucket_name, key_path=full_key_path)

        if(did_delete == True):
            file_exts_removed.append(current_extension) 
        else:
            error_exts.append(current_extension)
            error_messages.append(error_message)

    return file_exts_removed, error_exts, error_messages

# Example of all possible files deleted ['-BROWSE.jpg','-cmr.json','-thumb.jpg','.rename','.tar','.tif','.xml']
def get_key_paths_to_files(input_key_path_to_granule_id=''):
    # SETTINGS__all_extensions_MAXAR = ['-BROWSE.jpg','-cmr.json','-thumb.jpg','.rename','.tar','.tif','.xml']
    ret_list = []
    for ext_item in SETTINGS__all_extensions_MAXAR:
        ret_list.append(f'{input_key_path_to_granule_id}{ext_item}')
    return ret_list


def lambda_handler(event, context):
    run_did_fail = False
    err_info = ""
    success_info = ""
    try:
        debug_print(str_to_print="Starting a new run")

        # Looking at the Event Object:
        debug_print(str_to_print="Event Object", obj_out=event)

        # Extract bucket name and key from the event
        s3BucketArn = event['tasks'][0]['s3BucketArn']
        s3Key       = event['tasks'][0]['s3Key']
        debug_print(str_to_print="s3BucketArn", obj_out=s3BucketArn)                                        # TODO -- Update This Example to what is current:   arn:aws:s3:::csdap-cumulus-prod-internal
        debug_print(str_to_print="s3Key", obj_out=s3Key)                                                    # TODO -- Update This Example to what is current:   kstest/cmr_backups/planet/PSScene3Band/20150601_090322_090c_cmr.old

        # Split the CSV line to get the bucket and key
        src_bucket_name = s3BucketArn.split(':::')[1]                               
        src_key_path    = s3Key                                                     

        # Strip any extra spaces and quotes 
        src_bucket_name = src_bucket_name.strip()
        src_key_path = src_key_path.strip()
        debug_print(str_to_print="src_bucket_name", obj_out=src_bucket_name)                                # csdap-maxar-delivery
        debug_print(str_to_print="src_key_path", obj_out=src_key_path)                                      # css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002

        # Key Path to Granule ID
        key_path__to__granule_id = src_key_path  # Exact copy of the source

        # List of files to delete (Use the key_path to create a list of file extensions)
        list_of_s3_key_paths_to_delete = get_key_paths_to_files(input_key_path_to_granule_id=key_path__to__granule_id)
        debug_print(str_to_print="list_of_s3_key_paths_to_delete", obj_out=list_of_s3_key_paths_to_delete)  # list_of_s3_key_paths_to_delete:       ['css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-BROWSE.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-cmr.json', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-thumb.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.rename', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tar', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tif', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.xml']

        # Sleep for a very short amount of time to prevent throttle limit -- BEFORE ANY S3 Operations
        random_sleep()

        # Process the List now (Iterate and Delete all 7 expected files)
        # file_exts_removed = [] # Example of all 7 files deleted ['-BROWSE.jpg','-cmr.json','-thumb.jpg','.rename','.tar','.tif']
        file_exts_removed, error_exts, error_messages = execute_process_granule_key_path_list(bucket_name=src_bucket_name, list_of_s3_key_paths_to_delete=list_of_s3_key_paths_to_delete, original_key_path_to_granule=src_key_path)
        
        # After Running, print the results 
        debug_print(str_to_print="file_exts_removed", obj_out=file_exts_removed)                        # ['-BROWSE.jpg', '-cmr.json', '-thumb.jpg', '.rename', '.tar', '.tif', '.xml']
        debug_print(str_to_print="error_exts", obj_out=error_exts)                                      # []
        debug_print(str_to_print="error_messages", obj_out=error_messages)                              # []

        # Passing the invocation ID back in the success info.
        return {
            'statusCode': 200,
            'invocationSchemaVersion': event['invocationSchemaVersion'],
            'invocationId': event['invocationId'],
            'results': [
                {
                    'taskId': event['tasks'][0]['taskId'],
                    'resultCode': 'Succeeded',
                    'resultString': f'Removed: {file_exts_removed}  Errors: {error_exts}, Error Messages: {error_messages}'
                }
            ]
        }

    except:
        run_did_fail    = True
        success_info    = ""
        err_info        = str(sys.exc_info())
        #
        return {
            'statusCode': 500,
            'err_info': f'{err_info}'
        }



# EXAMPLE of the Test Input
# {
#   "invocationId": "some_long_string",
#   "job": {
#     "id": "e7306709-ea94-4dc0-863b-5c0d1bd20ee3"
#   },
#   "tasks": [
#     {
#       "taskId": "AAAAAAAAAAExFKoqBbA5bbIDWZB9c7NGhU0gGZLhY6jh/Lp6RiPJDFpU9bJ3KtvjxmOl9BwUPDHR9+qXkcXkYS2PO0Rb9ja6QTGRqWG7NHM4/xuLk3iBSMOxUKYSe7H7aNoFXHxSU+MFTPTxQcYIAcUQjYlLQbxa3EJP+qUTiJRJGWW/YZCDHkCo9tVQJCDyDHFs7fi/84z4g5SgCTencnb9OjD7kUuPA8as/pqRAyKhor83bk0fVI/rvZWwQPPWQmf4Y1aqhSd0ao/kf2qhlY99oOHNYWsJ3OedeWy/2d52K3RyadUDRARTLHqhs6hYl0qcPDW9pEY+cn8v9h8mHOZY4dCslCDrUoowtGb4hvenUC+fsdzkqb+x5k4THjuf3iLFxNMBkGtPrx5EWH5AviYZn3vo95ZioT9O2zIkmBgOq/kxNglsUFfwZzw2aRx4jQtRSR3BAmnA6sWFsPfslJNInYe1fGm4142II9dNR41lTyKQlmw/1DUieXEyVREEy3YLkewSDNzW+EOYKJjKrXwpKc+1yISxJrVJTAwWC0+pG/MaZlLBR3oWjBP33zOZTb+b3FmAteDMWrgsDM8ztSZGYUdy/TiNXHRQeLAs4zSb59qnsb0morzA4lOx8OKgegH2RmyzG+QJrm7Udr9/6do4zhKHAdjdJjYt6dQ8NDHLIUtvUh9Dp8d8pai2Ugiu17wTuQXhdGU8DzMcddZc39kRVHt0rCqKRt8u73BgDZo4faT5UJjWryzzKygtpxhMVdTqS0xMvdwdACDzOTyQ94W2Lhs0/yXxfKziesoAPcquUdFwc8J759rCDohGpisotOG62BfykeGTuw69WF278sIKCxFLkU7axw7Iybp7s0IC0P9FG7p1KZXNdyrU4h3oYU/kww+kQC+0j690rQa9/Db3pAsNdgQFRTDsrDrmHX3P7A+4P2RY3fzNJ0LDHXgqsmU+MUjlfbEiAAHxVjdCvFD+69+rCnjB27lY1FxnlJtx48RA6amOcXpU2Dc2qL1/zBdQ",
#       "s3BucketArn": "arn:aws:s3:::csdap-maxar-delivery",
#       "s3Key": "css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002",
#       "s3VersionId": "None"
#     }
#   ],
#   "invocationSchemaVersion": "1.0"
# }


# Example Success Output (with Debug Print Turned on, Before the REAL delete was turned on)
# Response:
# {
#   "statusCode": 200,
#   "invocationSchemaVersion": "1.0",
#   "invocationId": "some_long_string",
#   "results": [
#     {
#       "taskId": "AAAAAAAAAAExFKoqBbA5bbIDWZB9c7NGhU0gGZLhY6jh/Lp6RiPJDFpU9bJ3KtvjxmOl9BwUPDHR9+qXkcXkYS2PO0Rb9ja6QTGRqWG7NHM4/xuLk3iBSMOxUKYSe7H7aNoFXHxSU+MFTPTxQcYIAcUQjYlLQbxa3EJP+qUTiJRJGWW/YZCDHkCo9tVQJCDyDHFs7fi/84z4g5SgCTencnb9OjD7kUuPA8as/pqRAyKhor83bk0fVI/rvZWwQPPWQmf4Y1aqhSd0ao/kf2qhlY99oOHNYWsJ3OedeWy/2d52K3RyadUDRARTLHqhs6hYl0qcPDW9pEY+cn8v9h8mHOZY4dCslCDrUoowtGb4hvenUC+fsdzkqb+x5k4THjuf3iLFxNMBkGtPrx5EWH5AviYZn3vo95ZioT9O2zIkmBgOq/kxNglsUFfwZzw2aRx4jQtRSR3BAmnA6sWFsPfslJNInYe1fGm4142II9dNR41lTyKQlmw/1DUieXEyVREEy3YLkewSDNzW+EOYKJjKrXwpKc+1yISxJrVJTAwWC0+pG/MaZlLBR3oWjBP33zOZTb+b3FmAteDMWrgsDM8ztSZGYUdy/TiNXHRQeLAs4zSb59qnsb0morzA4lOx8OKgegH2RmyzG+QJrm7Udr9/6do4zhKHAdjdJjYt6dQ8NDHLIUtvUh9Dp8d8pai2Ugiu17wTuQXhdGU8DzMcddZc39kRVHt0rCqKRt8u73BgDZo4faT5UJjWryzzKygtpxhMVdTqS0xMvdwdACDzOTyQ94W2Lhs0/yXxfKziesoAPcquUdFwc8J759rCDohGpisotOG62BfykeGTuw69WF278sIKCxFLkU7axw7Iybp7s0IC0P9FG7p1KZXNdyrU4h3oYU/kww+kQC+0j690rQa9/Db3pAsNdgQFRTDsrDrmHX3P7A+4P2RY3fzNJ0LDHXgqsmU+MUjlfbEiAAHxVjdCvFD+69+rCnjB27lY1FxnlJtx48RA6amOcXpU2Dc2qL1/zBdQ",
#       "resultCode": "Succeeded",
#       "resultString": "Removed: ['-BROWSE.jpg', '-cmr.json', '-thumb.jpg', '.rename', '.tar', '.tif', '.xml']  Errors: [], Error Messages: []"
#     }
#   ]
# } 
#
# Function Logs:
# Tb+b3FmAteDMWrgsDM8ztSZGYUdy/TiNXHRQeLAs4zSb59qnsb0morzA4lOx8OKgegH2RmyzG+QJrm7Udr9/6do4zhKHAdjdJjYt6dQ8NDHLIUtvUh9Dp8d8pai2Ugiu17wTuQXhdGU8DzMcddZc39kRVHt0rCqKRt8u73BgDZo4faT5UJjWryzzKygtpxhMVdTqS0xMvdwdACDzOTyQ94W2Lhs0/yXxfKziesoAPcquUdFwc8J759rCDohGpisotOG62BfykeGTuw69WF278sIKCxFLkU7axw7Iybp7s0IC0P9FG7p1KZXNdyrU4h3oYU/kww+kQC+0j690rQa9/Db3pAsNdgQFRTDsrDrmHX3P7A+4P2RY3fzNJ0LDHXgqsmU+MUjlfbEiAAHxVjdCvFD+69+rCnjB27lY1FxnlJtx48RA6amOcXpU2Dc2qL1/zBdQ', 's3BucketArn': 'arn:aws:s3:::csdap-maxar-delivery', 's3Key': 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002', 's3VersionId': 'None'}], 'invocationSchemaVersion': '1.0'}
# s3BucketArn:    arn:aws:s3:::csdap-maxar-delivery
# s3Key:    css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002
# src_bucket_name:    csdap-maxar-delivery
# src_key_path:    css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002
# list_of_s3_key_paths_to_delete:    ['css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-BROWSE.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-cmr.json', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-thumb.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.rename', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tar', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tif', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.xml']
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-BROWSE.jpg
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-cmr.json
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-thumb.jpg
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.rename
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tar
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tif
# execute_s3_delete:    TODO - Uncomment the next line to ACTUALLY DELETE A FILE (bucket_name): csdap-maxar-delivery, (key_path): css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.xml
# file_exts_removed:    ['-BROWSE.jpg', '-cmr.json', '-thumb.jpg', '.rename', '.tar', '.tif', '.xml']
# error_exts:    []
# error_messages:    []
# END RequestId: 6d6d5067-693d-4ef6-8ec5-91f0da658a15
# REPORT RequestId: 6d6d5067-693d-4ef6-8ec5-91f0da658a15	Duration: 13.74 ms	Billed Duration: 14 ms	Memory Size: 128 MB	Max Memory Used: 85 MB	Init Duration: 442.43 ms

# Request ID: 6d6d5067-693d-4ef6-8ec5-91f0da658a15



# Full Example with Real Delete (Single Granule)
#
# Status: Succeeded
# Test Event Name: WV04_PAN_L1B_2017
#
# Response:
# {
#   "statusCode": 200,
#   "invocationSchemaVersion": "1.0",
#   "invocationId": "some_long_string",
#   "results": [
#     {
#       "taskId": "AAAAAAAAAAExFKoqBbA5bbIDWZB9c7NGhU0gGZLhY6jh/Lp6RiPJDFpU9bJ3KtvjxmOl9BwUPDHR9+qXkcXkYS2PO0Rb9ja6QTGRqWG7NHM4/xuLk3iBSMOxUKYSe7H7aNoFXHxSU+MFTPTxQcYIAcUQjYlLQbxa3EJP+qUTiJRJGWW/YZCDHkCo9tVQJCDyDHFs7fi/84z4g5SgCTencnb9OjD7kUuPA8as/pqRAyKhor83bk0fVI/rvZWwQPPWQmf4Y1aqhSd0ao/kf2qhlY99oOHNYWsJ3OedeWy/2d52K3RyadUDRARTLHqhs6hYl0qcPDW9pEY+cn8v9h8mHOZY4dCslCDrUoowtGb4hvenUC+fsdzkqb+x5k4THjuf3iLFxNMBkGtPrx5EWH5AviYZn3vo95ZioT9O2zIkmBgOq/kxNglsUFfwZzw2aRx4jQtRSR3BAmnA6sWFsPfslJNInYe1fGm4142II9dNR41lTyKQlmw/1DUieXEyVREEy3YLkewSDNzW+EOYKJjKrXwpKc+1yISxJrVJTAwWC0+pG/MaZlLBR3oWjBP33zOZTb+b3FmAteDMWrgsDM8ztSZGYUdy/TiNXHRQeLAs4zSb59qnsb0morzA4lOx8OKgegH2RmyzG+QJrm7Udr9/6do4zhKHAdjdJjYt6dQ8NDHLIUtvUh9Dp8d8pai2Ugiu17wTuQXhdGU8DzMcddZc39kRVHt0rCqKRt8u73BgDZo4faT5UJjWryzzKygtpxhMVdTqS0xMvdwdACDzOTyQ94W2Lhs0/yXxfKziesoAPcquUdFwc8J759rCDohGpisotOG62BfykeGTuw69WF278sIKCxFLkU7axw7Iybp7s0IC0P9FG7p1KZXNdyrU4h3oYU/kww+kQC+0j690rQa9/Db3pAsNdgQFRTDsrDrmHX3P7A+4P2RY3fzNJ0LDHXgqsmU+MUjlfbEiAAHxVjdCvFD+69+rCnjB27lY1FxnlJtx48RA6amOcXpU2Dc2qL1/zBdQ",
#       "resultCode": "Succeeded",
#       "resultString": "Removed: ['-BROWSE.jpg', '-cmr.json', '-thumb.jpg', '.rename', '.tar', '.tif', '.xml']  Errors: [], Error Messages: []"
#     }
#   ]
# }
#
# Function Logs:
# DWZB9c7NGhU0gGZLhY6jh/Lp6RiPJDFpU9bJ3KtvjxmOl9BwUPDHR9+qXkcXkYS2PO0Rb9ja6QTGRqWG7NHM4/xuLk3iBSMOxUKYSe7H7aNoFXHxSU+MFTPTxQcYIAcUQjYlLQbxa3EJP+qUTiJRJGWW/YZCDHkCo9tVQJCDyDHFs7fi/84z4g5SgCTencnb9OjD7kUuPA8as/pqRAyKhor83bk0fVI/rvZWwQPPWQmf4Y1aqhSd0ao/kf2qhlY99oOHNYWsJ3OedeWy/2d52K3RyadUDRARTLHqhs6hYl0qcPDW9pEY+cn8v9h8mHOZY4dCslCDrUoowtGb4hvenUC+fsdzkqb+x5k4THjuf3iLFxNMBkGtPrx5EWH5AviYZn3vo95ZioT9O2zIkmBgOq/kxNglsUFfwZzw2aRx4jQtRSR3BAmnA6sWFsPfslJNInYe1fGm4142II9dNR41lTyKQlmw/1DUieXEyVREEy3YLkewSDNzW+EOYKJjKrXwpKc+1yISxJrVJTAwWC0+pG/MaZlLBR3oWjBP33zOZTb+b3FmAteDMWrgsDM8ztSZGYUdy/TiNXHRQeLAs4zSb59qnsb0morzA4lOx8OKgegH2RmyzG+QJrm7Udr9/6do4zhKHAdjdJjYt6dQ8NDHLIUtvUh9Dp8d8pai2Ugiu17wTuQXhdGU8DzMcddZc39kRVHt0rCqKRt8u73BgDZo4faT5UJjWryzzKygtpxhMVdTqS0xMvdwdACDzOTyQ94W2Lhs0/yXxfKziesoAPcquUdFwc8J759rCDohGpisotOG62BfykeGTuw69WF278sIKCxFLkU7axw7Iybp7s0IC0P9FG7p1KZXNdyrU4h3oYU/kww+kQC+0j690rQa9/Db3pAsNdgQFRTDsrDrmHX3P7A+4P2RY3fzNJ0LDHXgqsmU+MUjlfbEiAAHxVjdCvFD+69+rCnjB27lY1FxnlJtx48RA6amOcXpU2Dc2qL1/zBdQ', 's3BucketArn': 'arn:aws:s3:::csdap-maxar-delivery', 's3Key': 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002', 's3VersionId': 'None'}], 'invocationSchemaVersion': '1.0'}
# s3BucketArn:    arn:aws:s3:::csdap-maxar-delivery
# s3Key:    css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002
# src_bucket_name:    csdap-maxar-delivery
# src_key_path:    css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002
# list_of_s3_key_paths_to_delete:    ['css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-BROWSE.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-cmr.json', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002-thumb.jpg', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.rename', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tar', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.tif', 'css/nga/WV04/1B/2017/203/WV04_ab212ea2-85fb-4564-923c-c0286bc82900-inv_X1BS_059096996120_01/WV04_20170722002258_ab212ea2-85fb-4564-923c-c0286bc82900-inv_17JUL22002258-P1BS-059096996120_01_P002.xml']
# file_exts_removed:    ['-BROWSE.jpg', '-cmr.json', '-thumb.jpg', '.rename', '.tar', '.tif', '.xml']
# error_exts:    []
# error_messages:    []
# END RequestId: ed03f3c5-2555-4a0b-9d7a-e2910e05c1aa
# REPORT RequestId: ed03f3c5-2555-4a0b-9d7a-e2910e05c1aa	Duration: 498.93 ms	Billed Duration: 499 ms	Memory Size: 128 MB	Max Memory Used: 86 MB	Init Duration: 447.80 ms
#
# Request ID: ed03f3c5-2555-4a0b-9d7a-e2910e05c1aa


# One Last Test before starting Batch Operations -- Turning on the Sleep Timer to stagger the executions
# Sleeping for: 0.07825984200370091 seconds.:    None
# REPORT RequestId: bf8e6c84-f498-475d-8d23-7847c74decff	Duration: 563.97 ms	Billed Duration: 564 ms	Memory Size: 128 MB	Max Memory Used: 86 MB	Init Duration: 447.19 ms