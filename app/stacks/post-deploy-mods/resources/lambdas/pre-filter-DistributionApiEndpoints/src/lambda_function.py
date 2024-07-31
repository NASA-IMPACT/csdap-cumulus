# Import Section
import json

# For catching generic errors
import sys

# To call another lambda, from this lambda
import boto3


# SETTINGS
#
# This function's name (for logging purposes)
#this_function_name = "cumulus-prod-pre-filter-DistributionApiEndpoints"
this_function_name = "ENV_VAR__CUMULUS_PREFIX-pre-filter-DistApiEndpoints"

#
# If this is set to False, this function does nothing extra than the original lambda did, it just allows a pass through
# If this is set to True, this function does the normal request, then attempts to detect a request for a file, if this IS a file request, then it checks EULA permissions for the current user
is_post_EULA_filter_enabled = True  # True # False
#
# Which dynamo DB table holds the Access Tokens after a succesful authentication?
#dynamo_db__table_name = 'cumulus-prod-DistributionAccessTokensTable'
dynamo_db__table_name = 'ENV_VAR__CUMULUS_PREFIX-DistributionAccessTokensTable'

#
# All Possible Dataset directories by Vendor - When a new vendor or dataset is added, add to this list.
vendor_to_dataset_map = {
  'planet':
    [
      'planet',
      'PSScene3Band___1'
    ],
  'maxar':
    [
      'WV04_MSI_L1B___1', 'WV04_Pan_L1B___1',
      'WV03_MSI_L1B___1', 'WV03_Pan_L1B___1',
      'WV02_MSI_L1B___1', 'WV02_Pan_L1B___1',
      'WV01_MSI_L1B___1', 'WV01_Pan_L1B___1',
      'GE01_MSI_L1B___1', 'GE01_Pan_L1B___1'
    ]
}

# Testing a new Vendor 'testvendor'
# vendor_to_dataset_map = {
#   'planet':
#     [
#       'planet',
#       'PSScene3Band___1'
#     ],
#   'maxar':
#     [
#       'WV04_MSI_L1B___1', 'WV04_Pan_L1B___1',
#       'WV03_MSI_L1B___1', 'WV03_Pan_L1B___1',
#       'WV02_MSI_L1B___1', 'WV02_Pan_L1B___1',
#       'WV01_MSI_L1B___1', 'WV01_Pan_L1B___1',
#       'GE01_MSI_L1B___1'
#     ],
#   'testvendor':
#     [
#       'GE01_Pan_L1B___1'
#     ]
# }


# In Code Docs - Function Process.
#
# (1) Make the normal request (Call the other lambda and hold on to it's return value)
# (2) If the is_post_EULA_filter_enabled, is set to False, let the original function's output just pass right through
# (3) If the is_post_EULA_filter_enabled, is set to True, Then we check the request and grant or deny permissions based on the request and info obtained from the user's cognito properties and dataset map
# (3a) If the user's request is not valid, we return an error message that simply says, "insufficient permissions"
# (3b) If the user's request is valid, a file download should start, just the same way as it used to before this filter was installed.


# Main Lambda Handler
def lambda_handler(event, context):
  print(f'{this_function_name}:         STARTED')
  #
  print(f'  input param: event:   {event}')
  print(f'  input param: context: {context}')
  #
  print(f'is_post_EULA_filter_enabled is set to {is_post_EULA_filter_enabled}')

  # Make the normal request first.

  # Default event to return
  ret_event = {'statusCode': 200, 'body': json.dumps('Default')}

  # Try catch for debugging generic errors
  has_error = False
  error_msg = ''
  try:
    # Create the boto3 client
    client = boto3.client('lambda')

    # Call the Original Lambda here - Passing in the original event parameter
    #
    # Important Note: This requires the execution role to have permissions
    # #
    # # FunctionName='arn:aws:lambda:us-west-2:410469285047:function:cumulus-prod-DistributionApiEndpoints',
    response__From_Original_Lambda = client.invoke(
      FunctionName='arn:aws:lambda:us-west-2:410469285047:function:ENV_VAR__CUMULUS_PREFIX-DistributionApiEndpoints',
      InvocationType='RequestResponse',
      Payload=json.dumps(event)
    )

    # Overwrite the original return - This sends the output DIRECTLY back through the API Gateway return mechanism without modifying it.
    ret_event = json.loads(response__From_Original_Lambda['Payload'].read())

  except:
    sysErrorData = str(sys.exc_info())
    has_error = True
    error_msg = f'Error invoking Original Lambda.  Sys Error Info: {sysErrorData}'

  # If an error occured when calling the original Lambda, we must exit right away.
  if (has_error == True):
    log_error = {'statusCode': 200, 'body': json.dumps(
      f'{this_function_name}:  There was an error calling the other function.  (error_msg): {error_msg}')}
    print(f'log_error: {log_error}')
    ret_event = {'statusCode': 200, 'body': json.dumps(f'An Error occured.')}
  else:
    # This is the point in the code where we determine how to check for EULA
    if (is_post_EULA_filter_enabled == True):
      print(f'The post EULA filter was turned ON.  Proceeding with next Checkpoints...')

      print(
        f'Now checking to see if this is a specific file reques by a logged in user.')
      # is_logged_in_and_specific_s3_file_request = False
      try:

        # This is the path to the file the user is requesting.
        # Example1: "/csdap-cumulus-prod-protected/planet/PSScene3Band/20190603_235523_0f4c_thumb"
        # Example2: "/csdap-cumulus-uat-protected/WV02_Pan_L1B___1/2009/364/WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005/WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005.ntf"
        requested_path_str = event['path']
        print(f'requested_path_str: {requested_path_str}')

        # TODO - Check the path object for a specific kind of structure that identifies it??  Or maybe check another property for S3?

        # Has an accessToken (which means they are logged in)
        headers_Cookie_obj = event['headers']['Cookie']
        print(f'headers_Cookie_obj: {headers_Cookie_obj}')

        # Getting the access Token (to be used to retrive the correct record from DynamoDB)
        accessToken = headers_Cookie_obj.split("accessToken=")[1].split(";")[
          0]  # IF the user is logged in, this accessToken will be in an expected location.
        print(f'accessToken from request: {accessToken}')

        # Get the Eula Acceptance String from dynamo DB
        # Note: if this funciton fails, a blank str is returned, which later gets denied access.
        current_user__eula_acceptance_str = get_eulaAcceptances_from_token_from_dyanmoDB(
          accessToken=accessToken)
        print(
          f'Confirmed current_user__eula_acceptance_str: {current_user__eula_acceptance_str}')

        # Convert the User's EULA Acceptance String into an array of strings
        current_user__eula_acceptance_vendor_list = convert_vendor_string_into_vendor_list(
          input_string=current_user__eula_acceptance_str)
        print(
          f'Confirmed current_user__eula_acceptance_vendor_list: {current_user__eula_acceptance_vendor_list}')

        # Get the Vendor's Dataset Directory that the user was trying to request
        current_user__requested_dataset_directory_name = convert_requested_path_to_dataset_dir_name(
          input_path=requested_path_str)
        print(
          f'current_user__requested_dataset_directory_name: {current_user__requested_dataset_directory_name}')

        # Finally get the decision of if this user has access or not.
        # current_user_has_vendor_access = does_dataset_dir_have_vendor_access(dataset_dir_name="", vendor_access_list=[], vendor_to_dataset_map={})
        current_user_has_vendor_access = does_dataset_dir_have_vendor_access(
          dataset_dir_name=current_user__requested_dataset_directory_name,
          vendor_access_list=current_user__eula_acceptance_vendor_list,
          vendor_to_dataset_map=vendor_to_dataset_map)
        print(f'current_user_has_vendor_access: {current_user_has_vendor_access}')

        if (current_user_has_vendor_access == True):
          # Do nothing here, if this was a file request and we passed all these checks, then the file download should start for them.
          print(f'User DOES have access to the requested dataset.')

        else:
          print(
            f'User does NOT have access to the requested dataset.  Sending back an error message to the user.')

          # Return Status code on error.
          # Note: 200 means all is ok, are we passing back an HTML error code along with the message (because they don't have permission)?
          # or, are we passing back a 200 because the function executed correctly and the webpage technicaly is doing what it is supposed to?
          statusCode = 200

          msg_to_user = f'"insufficient permissions"'
          # ret_event = {'statusCode': 200, 'body': json.dumps('Hello from Lambda!:  cumulus-uat-pre-filter-DistApiEndpoints') }
          ret_event = {'statusCode': statusCode, 'body': json.dumps(f'{msg_to_user}')}


      except:
        sysErrorData = str(sys.exc_info())
        error_msg = f'This is likely NOT a specific S3 file request from a logged in user.  In case this is an error, here is the system "except:" info.  Sys Error Info: {sysErrorData}'
        print(error_msg)

      # TODO - Write that function to detect the type of request

    else:
      print(
        f'The post EULA filter was turned OFF.  Passing the event back to the original requester.')

  # END OF:       if(has_error == True):      else:

  # return {
  #     'statusCode': 200,
  #     'body': json.dumps('Hello from Lambda!')
  # }

  # DEBUG AND TESTING!!
  # ret_event = {'statusCode': 200, 'body': json.dumps(f'THIS PART OF THE APPLICATION IS RUNNING IN TEST MODE RIGHT NOW.  -- if you still see this message after retrying a few hoursl ater, please contact Kris!') }
  #
  print(f'{this_function_name}:         Reached the End!  Returning now.')

  # Return the event
  return ret_event


# Check Retrieve the current user's EULA Acceptance from dynamoDB using their AccessToken.
# # The AccessToken is passed into the request after a user successfully logs in.
# # The user's record gets processed and stored into local DynamoDB by the original lambda function which gets called BEFORE this one.
#
# get_eulaAcceptances_from_token_from_dyanmoDB(accessToken=accessToken)
def get_eulaAcceptances_from_token_from_dyanmoDB(accessToken="UNSET"):
  # Default as blank, which means no access.
  ret_eulaAcceptance_Str = ''

  print(
    f'get_eulaAcceptances_from_token_from_dyanmoDB: Input accessToken: {accessToken}')

  try:
    # Initialize a session using Amazon DynamoDB
    dynamodb = boto3.resource('dynamodb')

    # Get the table object
    table = dynamodb.Table(dynamo_db__table_name)

    # Perform a scan to get all items
    response = table.scan()
    items = response.get('Items', [])

    if not items:
      no_items_error = f'There was an error when getting items from the dynamodb table.  The Items from response.get("items", []) was null.'
      print(no_items_error)

    row_counter = 0
    for item in items:
      # print(f'Current Row: {row_counter}:  item:  {item}')
      item__accessToken = item['accessToken']
      item__tokenInfo__eulaAcceptances = item['tokenInfo']['eulaAcceptances']
      if (item__accessToken == accessToken):
        print(
          f'Found a matching access token.  Now taking property tokenInfo.eulaAcceptances: {item__tokenInfo__eulaAcceptances}')
        ret_eulaAcceptance_Str = str(item__tokenInfo__eulaAcceptances)
      row_counter = row_counter + 1


  except:
    sysErrorData = str(sys.exc_info())
    error_msg = f'Error getting eula Acceptances from DynamoDB.  Sys Error Info: {sysErrorData}'
    ret_eulaAcceptance_Str = ''

  return ret_eulaAcceptance_Str


# Function to convert a string like this: "Vendor One, Vendor Two" into an array like this: ["vendorone", "vendortwo"]
def convert_vendor_string_into_vendor_list(input_string=""):
  ret_array = []

  # Validation - Check if the input string is empty, if so, return an empty list, which will fail the access checkpoint later.
  if not input_string.strip():
    return []

  # Split the string by comma, remove internal spaces, strip extra spaces, and convert each element to lowercase
  # ret_array = [element.replace(" ", "").strip().lower() for element in input_string.split('.') if element.strip()]
  ret_array = []

  # Split the string by comma and iterate over each element
  for element in input_string.split(','):
    # Check if the element is not just whitespace
    if element.strip():
      # Remove internal spaces, strip trailing spaces, convert to lowercase
      cleaned_element = element.replace(" ", "").strip().lower()
      ret_array.append(cleaned_element)

  return ret_array


# Convert the user requested path into a dataset directory name.
#
# # Convert this:
# "/csdap-cumulus-uat-protected/WV02_Pan_L1B___1/2009/364/WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005/WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005.ntf"
# # To This:
# "WV02_Pan_L1B___1"
#
# At this time, the parent dataset directory is always the second directory.
# # For MAXAR, there are multiple dataset directories at this level                         -- Example Items look like this:    "WV02_Pan_L1B___1" and "GE01_MSI_L1B___1"
# # For Planet, there is a vendor level directory at this level, so it is a bit simpler     -- Example Item looks like this:    "planet"
def convert_requested_path_to_dataset_dir_name(input_path=""):
  # Default return to blank string.
  ret_dataset_dir_name = ""

  # Validation - Check to see if the input was an empty string.  If it is, then return another empty string (which will later fail the access checkpoint.)
  if (input_path == ""):
    return ""

  # Split the input path by a forward slash
  path_parts = input_path.split('/')
  print(
    f'Split path_parts: {path_parts}')  # Example: ['', 'csdap-cumulus-uat-protected', 'WV02_Pan_L1B___1', '2009', '364', 'WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005', 'WV02_20091230151804_10300100032C7800_09DEC30151804-P1BS-501603505040_01_P005.ntf']

  # Get the element at position 2 (third item in the directory path) -- remember, first item is blank string.
  ret_dataset_dir_name = path_parts[2]  # input_path.split('/')[2]

  # Return the result
  return ret_dataset_dir_name


# Check the parts of the 'vendor_to_dataset_map' (from settings) that are in the 'vendor_access_list' (from the user) to see if this 'dataset_dir_name' (from the user) has access or not.
def does_dataset_dir_have_vendor_access(dataset_dir_name="", vendor_access_list=[],
                                        vendor_to_dataset_map={}):
  # Always default access to False
  ret_has_access = False

  # Validation Section - If any of the inputs are blank, then deny access right here.
  #
  # If a blank string made it's way in here, deny the access (return False)
  if (dataset_dir_name == ""):
    print(f'has_access: input: dataset_dir_name was a blank string. ""')
    return False
  #
  if (vendor_access_list == []):
    print(f'has_access: input: vendor_access_list was an empty list [].')
    return False
  #
  # If the configuration is broken somehow (blank object)  // if not vendor_to_dataset_map:   is a true statement if vendor_to_dataset_map is ONLY defined by {} (blank object)
  if not vendor_to_dataset_map:
    print("has_access: input: vendor_to_dataset_map was an empty object {}.")
    return False

  # Get the keys to the vendor to dataset map
  vendor_to_dataset_map__keys = vendor_to_dataset_map.keys()
  print(f'has_access: vendor_to_dataset_map__keys {vendor_to_dataset_map__keys}')

  # Now Use the vendor_access_list to check parts of the map and see if any of the directory paths match.
  for vendor_access_item in vendor_access_list:

    # Check the map, but ONLY if the current vendor name is in the keys of the map
    # # This part is critical, this is how we will NOT give access to a directory that is not included in the vendor access list, which comes directly from the EULA Acceptance String
    if (vendor_access_item in vendor_to_dataset_map__keys):
      current_vendor_dirs_to_check = vendor_to_dataset_map[vendor_access_item]

      # Now Iterate all the Directories found in the part of the Vendor map that is for this current vendor which was in the vendor access list.
      for current_vendor_dir in current_vendor_dirs_to_check:
        if (current_vendor_dir == dataset_dir_name):
          ret_has_access = True
          print(
            f'has_access: Found a match {current_vendor_dir} found in the map matches with the requested directory: {dataset_dir_name}')
    else:
      # The only condition when this block should get hit is if there is a vendor listed on the user's EULA Acceptance List that does not currently exist in the vendor_to_dataset_map.  It might be a new vendor, or an error, or a mis spelled word?
      print(
        f'has_access: Warning:, Vendor, {vendor_access_item} was passed in but not found in the (vendor_to_dataset_map__keys): {vendor_to_dataset_map__keys}.  Is this a new vendor that needs to be added?  This might be an error, check the spelling of the Vendor which appears on the EULA Acceptance string')

  # Return the decision.
  return ret_has_access

# END OF LAMBDA
