# step_03__getting_granule_id_lists.py

# python step_03__getting_granule_id_lists.py


import datetime



# Settings for OLD_NGAP_MAXAR
SETTINGS__is_run__OLD_NGAP_MAXAR 		= False #True
SETTINGS__MODE__OLD_NGAP_MAXAR_Paths 	= [
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}
]



# Settings for MCP_MAXAR
SETTINGS__is_run__MCP_MAXAR 	= True
SETTINGS__MODE__MCP_MAXAR_Paths = [
	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt'},
	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt'},
	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt'},
	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt'},
	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt'}

]



### ######################################################
### ### SECTION ### MCP Convert File List to Just the Path to a Granule (Unique List)
### ######################################################





# For The MCP List, I just need to convert the large list of each individual file down to just a path to the granule.
# This means that after removing the end filename part, we will have something like 9 duplicates per granule.
# The last step will be to just remove the duplicates on the outfile.
# The file size (and memory size) of this list should be reduced by about 90% when doing it this way.
def process_MODE__MCP_MAXAR_Path(mcp_maxar_path_object={}):
	counter__total_lines 				= 0
	counter__granule_lines 				= 0
	granule_path_only_lines 			= []
	num_of_granule_paths 				= 0 
	#num_of_granule_paths_BEFORE_unique 	= 0 
	#num_of_granule_paths_AFTER_unique 		= 0 
	try:
		# Open the File at 'in_file' and read the list into memory
		file_path__in_file 		= mcp_maxar_path_object['in_file']
		file_path__out_file 	= mcp_maxar_path_object['out_file']
		#
		with open(file_path__in_file, 'r') as in_file:
			# Parse the list and add just the Granule Ids to a new list
			# Iterate through each line in the file
			for line in in_file:
				# Get the Granule ID
				#if(counter__total_lines == 1):
				# First, Ignore the items that do not have -thumb.jpg
				# -thumb.jpg
				if('-thumb.jpg' in line):
					granule_path = MCP_MAXAR__get_granule_path_from_input_str(input_str=line)
					granule_path_only_lines.append(granule_path)
					counter__granule_lines = counter__granule_lines + 1
				#
				# Increment the counter.
				#if(counter__total_lines == 1):
				#	print(f'DEBUG: (granule_id): {granule_id}')
				counter__total_lines = counter__total_lines + 1

		# Make sure the list of Granules is unique
		num_of_granules__BEFORE 	= len(granule_path_only_lines)
		granule_path_only_lines 	= list(set(granule_path_only_lines))
		num_of_granules__AFTER 		= len(granule_path_only_lines)
		print(f'  Num of Granule Paths BEFORE and AFTER {num_of_granules__BEFORE} and {num_of_granules__AFTER}')

		# Save the new list to a new file at 'out_file' (overwriting if it already exists)
		with open(file_path__out_file, 'w') as out_file:
			# Iterate each line in the list. 
			for line_to_write in granule_path_only_lines:
				# Write the line and a newline char ('\n') at the end
				#out_file.write(line_to_write+'\n')
				out_file.write(line_to_write)
		num_of_granule_paths = len(granule_path_only_lines)
		print(f'  process_MODE__MCP_MAXAR_Path: Saved {num_of_granule_paths} Granule IDs to a File saved at: {file_path__out_file}')

	except Exception as e:
		print(f'process_MODE__MCP_MAXAR_Path: ERROR: An error occured: {e}')

	num_of_granule_paths = len(granule_path_only_lines)
	print(f'  process_MODE__MCP_MAXAR_Path: Function Finished with {num_of_granule_paths} Granule Paths and {counter__total_lines} Total Lines Processed ')


# Convert this: 		WV04_Pan_L1B___1/2018/297/WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009/WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009-thumb.jpg
# To this: 				WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009
def MCP_MAXAR__get_granule_path_from_input_str(input_str=""):
	ret_str = ''

	# Expected input (An Already filtered down to just the thumbfile link)
	# # '"csdap-maxar-delivery","css/nga/WV04/1B/2018/297/WV04_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_X1BS_059420300030_01/WV04_20181024105141_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_18OCT24105141-P1BS-059420300030_01_P009-thumb.jpg"'

	try:
		# First, remove '"csdap-maxar-delivery","'
		str_1 = input_str.replace('"csdap-maxar-delivery","','') 	# 'css/nga/WV04/1B/2018/297/WV04_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_X1BS_059420300030_01/WV04_20181024105141_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_18OCT24105141-P1BS-059420300030_01_P009-thumb.jpg"'

		# Next, Remove the filename and last quote
		ret_str = str_1.replace('-thumb.jpg"', '') 					# 'css/nga/WV04/1B/2018/297/WV04_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_X1BS_059420300030_01/WV04_20181024105141_9d1b1558-19ce-4d6e-873e-1a726f579bb3-inv_18OCT24105141-P1BS-059420300030_01_P009'
	
	except Exception as e:
		# On Error, set return string to blank
		#print(f'    err (e): {e}')
		ret_str = ''
	return ret_str









### ######################################################
### ### SECTION ### OLD_NGAP Convert To just a Granule ID
### ######################################################


# For the OLD_NGAP Lists, I need to filter down to ONLY the Granule ID.  
# Again, there may be duplicates depending on which source is used (I believe I picked the public bucket so it would only be a list of thumbs, which means no duplicates)
# The file size of this list will be reduced by a very large amount (greater than 90% reduction, maybe 98% since paths are all very long), since the rest of the path is not part of it.
def process_MODE__OLD_NGAP_MAXAR_Paths(old_ngap_maxar_path_object={}):
	
	counter__total_lines 	= 0
	granule_id_lines 		= []
	num_of_granule_ids 		= 0
	try:
		# Open the File at 'in_file' and read the list into memory
		file_path__in_file 		= old_ngap_maxar_path_object['in_file']
		file_path__out_file 	= old_ngap_maxar_path_object['out_file']
		#
		with open(file_path__in_file, 'r') as in_file:
			# Parse the list and add just the Granule Ids to a new list
			# Iterate through each line in the file
			for line in in_file:
				# Get the Granule ID
				#if(counter__total_lines == 1):
				granule_id = OLD_NGAP_MAXAR__get_granule_id_from_input_str(input_str=line)
				granule_id_lines.append(granule_id)
				#
				# Increment the counter.
				#if(counter__total_lines == 1):
				#	print(f'DEBUG: (granule_id): {granule_id}')
				counter__total_lines = counter__total_lines + 1

		# Make sure the list of Granules is unique
		num_of_granules__BEFORE = len(granule_id_lines)
		granule_id_lines = list(set(granule_id_lines))
		num_of_granules__AFTER = len(granule_id_lines)
		print(f'  Num of Granules BEFORE and AFTER {num_of_granules__BEFORE} and {num_of_granules__AFTER}')

		# Save the new list to a new file at 'out_file' (overwriting if it already exists)
		with open(file_path__out_file, 'w') as out_file:
			# Iterate each line in the list. 
			for line_to_write in granule_id_lines:
				# Write the line and a newline char ('\n') at the end
				#out_file.write(line_to_write+'\n')
				out_file.write(line_to_write)
		num_of_granule_ids = len(granule_id_lines)
		print(f'  process_MODE__OLD_NGAP_MAXAR_Paths: Saved {num_of_granule_ids} Granule IDs to a File saved at: {file_path__out_file}')

	except Exception as e:
		print(f'process_MODE__OLD_NGAP_MAXAR_Paths: ERROR: An error occured: {e}')

	num_of_granule_ids = len(granule_id_lines)
	print(f'  process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with {num_of_granule_ids} Granules and {counter__total_lines} Total Lines Processed ')


# Convert this: 		WV04_Pan_L1B___1/2018/297/WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009/WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009-thumb.jpg
# To this: 				WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009
def OLD_NGAP_MAXAR__get_granule_id_from_input_str(input_str=""):
	ret_str = ''
	try:
		# Remove directory paths
		str_1 = input_str.split('/')[-1] 			# 'WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009-thumb.jpg'
		#print(f'    str_1: {str_1}')

		# Remove '-thumb.jpg'
		ret_str = str_1.replace('-thumb.jpg', '')  	# 'WV04_20181024105205_bc4e6462-5a0b-4958-ad90-86f9874314bb-inv_18OCT24105205-P1BS-059420300020_01_P009'
		#print(f'    ret_str: {ret_str}')

	except Exception as e:
		# On Error, set return string to blank
		#print(f'    err (e): {e}')
		ret_str = ''
	return ret_str


def main():
	print(f'main:  STARTED')
	datetime__START = datetime.datetime.utcnow()

	if(SETTINGS__is_run__OLD_NGAP_MAXAR == True):
		print(f'')
		print(f'Converting OLD_NGAP MAXAR lists into just Lists of Granule IDs...')
		print(f'')
		print(f'Settings Items:')
		print(f'  SETTINGS__is_run__OLD_NGAP_MAXAR:     {SETTINGS__is_run__OLD_NGAP_MAXAR}')
		print(f'  SETTINGS__MODE__OLD_NGAP_MAXAR_Paths: {SETTINGS__MODE__OLD_NGAP_MAXAR_Paths}')
		print(f'')
		#
		for path_obj in SETTINGS__MODE__OLD_NGAP_MAXAR_Paths:
			print(f'---------------------------------------------------------------')
			#print(f'TODO!!! PROCESS THIS ITEM!!  OLD_NGAP_MAXAR: (path_obj): {path_obj}')
			process_MODE__OLD_NGAP_MAXAR_Paths(old_ngap_maxar_path_object=path_obj)
			print(f'---------------------------------------------------------------')


	if(SETTINGS__is_run__MCP_MAXAR == True):
		print(f'')
		print(f'Converting MCP MAXAR Lists into just List of Unique Granule Paths...')
		print(f'')
		print(f'Settings Items:')
		print(f'  SETTINGS__is_run__MCP_MAXAR:     {SETTINGS__is_run__MCP_MAXAR}')
		print(f'  SETTINGS__MODE__MCP_MAXAR_Paths: {SETTINGS__MODE__MCP_MAXAR_Paths}')
		print(f'')
		#
		for path_obj in SETTINGS__MODE__MCP_MAXAR_Paths:
			print(f'---------------------------------------------------------------')
			#print(f'TODO!!! PROCESS THIS ITEM!!  MCP_MAXAR: (path_obj): {path_obj}')
			process_MODE__MCP_MAXAR_Path(mcp_maxar_path_object=path_obj)
			print(f'---------------------------------------------------------------')




	datetime__END = datetime.datetime.utcnow()
	total_time__str = str(datetime__END-datetime__START)
	print(f'main:  Reached the End  -- Total Execution Time: {total_time__str}')

main()



# ###################################
# # Output --- MCP_MAXAR
# ###################################

# ➜  mcp_MAXAR_deletes__q4_2024 python step_03__getting_granule_id_lists.py
# main:  STARTED

# Converting MCP MAXAR Lists into just List of Unique Granule Paths...

# Settings Items:
#   SETTINGS__is_run__MCP_MAXAR:     True
#   SETTINGS__MODE__MCP_MAXAR_Paths: [{'in_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt'}, {'in_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt'}, {'in_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt'}, {'in_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt'}, {'in_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt'}]

# ---------------------------------------------------------------
#   Num of Granule Paths BEFORE and AFTER 1845101 and 1845101
#   process_MODE__MCP_MAXAR_Path: Saved 1845101 Granule IDs to a File saved at: step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt
#   process_MODE__MCP_MAXAR_Path: Function Finished with 1845101 Granule Paths and 13383320 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granule Paths BEFORE and AFTER 5078347 and 5078347
#   process_MODE__MCP_MAXAR_Path: Saved 5078347 Granule IDs to a File saved at: step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt
#   process_MODE__MCP_MAXAR_Path: Function Finished with 5078347 Granule Paths and 40729489 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granule Paths BEFORE and AFTER 10339661 and 10339661
#   process_MODE__MCP_MAXAR_Path: Saved 10339661 Granule IDs to a File saved at: step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt
#   process_MODE__MCP_MAXAR_Path: Function Finished with 10339661 Granule Paths and 79638458 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granule Paths BEFORE and AFTER 4627513 and 4627513
#   process_MODE__MCP_MAXAR_Path: Saved 4627513 Granule IDs to a File saved at: step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt
#   process_MODE__MCP_MAXAR_Path: Function Finished with 4627513 Granule Paths and 36696704 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granule Paths BEFORE and AFTER 12705 and 12705
#   process_MODE__MCP_MAXAR_Path: Saved 12705 Granule IDs to a File saved at: step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt
#   process_MODE__MCP_MAXAR_Path: Function Finished with 12705 Granule Paths and 93754 Total Lines Processed 
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:00:57.396265
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 ls -lah step_02__filtering_large_manifests_down/filtered_lists
# total 58898008
# drwxr-xr-x  7 kstanto1  staff   224B Nov  3 15:50 .
# drwxr-xr-x  4 kstanto1  staff   128B Oct 29 22:51 ..
# -rw-r--r--@ 1 kstanto1  staff   2.2G Oct 29 23:32 MCP__Delivery_Bucket__GE01_1B__BOTH.txt
# -rw-r--r--@ 1 kstanto1  staff   6.7G Oct 29 23:33 MCP__Delivery_Bucket__WV01_1B__BOTH.txt
# -rw-r--r--@ 1 kstanto1  staff    13G Oct 29 23:37 MCP__Delivery_Bucket__WV02_1B__BOTH.txt
# -rw-r--r--@ 1 kstanto1  staff   6.0G Oct 29 23:39 MCP__Delivery_Bucket__WV03_1B__BOTH.txt
# -rw-r--r--@ 1 kstanto1  staff    20M Oct 29 23:39 MCP__Delivery_Bucket__WV04_1B__BOTH.txt
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 ls -lah step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists
# total 6251584
# drwxr-xr-x  7 kstanto1  staff   224B Nov  3 20:36 .
# drwxr-xr-x  6 kstanto1  staff   192B Nov  3 18:56 ..
# -rw-r--r--  1 kstanto1  staff   255M Nov  3 20:36 MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt
# -rw-r--r--  1 kstanto1  staff   702M Nov  3 20:36 MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt
# -rw-r--r--  1 kstanto1  staff   1.4G Nov  3 20:36 MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt
# -rw-r--r--  1 kstanto1  staff   640M Nov  3 20:36 MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt
# -rw-r--r--  1 kstanto1  staff   2.3M Nov  3 20:36 MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt
# ➜  mcp_MAXAR_deletes__q4_2024 





# ###################################
# # Output --- OLD_NGAP_MAXAR
# ###################################


# ➜  mcp_MAXAR_deletes__q4_2024 python step_03__getting_granule_id_lists.py
# main:  STARTED

# Converting OLD_NGAP MAXAR lists into just Lists of Granule IDs...

# Settings Items:
#   SETTINGS__is_run__OLD_NGAP_MAXAR:     True
#   SETTINGS__MODE__OLD_NGAP_MAXAR_Paths: [{'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}, {'in_file': 'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}]

# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 722623 and 722623
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 722623 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 722623 Granules and 722623 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 5023086 and 5023086
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 5023086 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 5023086 Granules and 5023086 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 3111290 and 3111290
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 3111290 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 3111290 Granules and 3111290 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 1882712 and 1882712
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 1882712 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 1882712 Granules and 1882712 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 2515801 and 2515801
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 2515801 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 2515801 Granules and 2515801 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 6753 and 6753
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 6753 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 6753 Granules and 6753 Total Lines Processed 
# ---------------------------------------------------------------
# ---------------------------------------------------------------
#   Num of Granules BEFORE and AFTER 6753 and 6753
#   process_MODE__OLD_NGAP_MAXAR_Paths: Saved 6753 Granule IDs to a File saved at: step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
#   process_MODE__OLD_NGAP_MAXAR_Paths: Function Finished with 6753 Granules and 6753 Total Lines Processed 
# ---------------------------------------------------------------

# Converting MCP MAXAR Lists into just List of Unique Granule Paths...

# Settings Items:
#   SETTINGS__is_run__MCP_MAXAR:     True
#   SETTINGS__MODE__MCP_MAXAR_Paths: []

# main:  Reached the End  -- Total Execution Time: 0:00:12.138899
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 
# ➜  mcp_MAXAR_deletes__q4_2024 ls -lah step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW
# total 4925360
# drwxr-xr-x  10 kstanto1  staff   320B Oct 29 22:09 .
# drwxr-xr-x   4 kstanto1  staff   128B Nov  3 18:56 ..
# -rw-r--r--@  1 kstanto1  staff   6.0K Oct 29 10:49 .DS_Store
# -rw-r--r--@  1 kstanto1  staff   131M Oct 29 11:29 GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   910M Oct 29 11:10 WV01_Pan_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   564M Oct 29 11:04 WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   341M Oct 29 10:54 WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   456M Oct 29 10:52 WV03_Pan_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   1.5M Oct 29 10:49 WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# -rw-r--r--@  1 kstanto1  staff   1.5M Oct 29 10:49 WV04_Pan_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv
# ➜  mcp_MAXAR_deletes__q4_2024 ls -lah step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists                       
# total 1998128
# drwxr-xr-x  9 kstanto1  staff   288B Nov  3 19:22 .
# drwxr-xr-x  6 kstanto1  staff   192B Nov  3 18:56 ..
# -rw-r--r--  1 kstanto1  staff    53M Nov  3 19:22 GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   369M Nov  3 19:22 WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   228M Nov  3 19:22 WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   138M Nov  3 19:22 WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   185M Nov  3 19:22 WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   666K Nov  3 19:22 WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# -rw-r--r--  1 kstanto1  staff   666K Nov  3 19:22 WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt
# ➜  mcp_MAXAR_deletes__q4_2024 



# DRAFT
# # IMPORTANT
# This script has multiple modes of operation.  
# For now the two modes are MCP_MAXAR and OLD_NGAP_MAXAR
# This is toggled by a setting below.
#
# Setting for which Mode we are operating in.
