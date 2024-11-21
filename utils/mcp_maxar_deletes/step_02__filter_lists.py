# step_02__filter_lists.py

# python step_02__filter_lists.py

import datetime


# # Quick Script Metrics
# Processing a 32 GB csv file took about 40 seconds.
# A way to make this more efficient would be to only iterate the large list once (and do all the filtering horizontally (all at once))
# Not needed - Code is easier to follow when it is more linear like this.


# Here are the lists I need to KEEP (Into Separate output files)
#
# String Starts with: "csdap-maxar-delivery","css/nga/GE01/1B/
# String Starts with: "csdap-maxar-delivery","css/nga/WV01/1B/
# String Starts with: "csdap-maxar-delivery","css/nga/WV02/1B/
# String Starts with: "csdap-maxar-delivery","css/nga/WV03/1B/
# String Starts with: "csdap-maxar-delivery","css/nga/WV04/1B/


SETTINGS__Input_File = 'manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt'
SETTINGS__Output_Objects = [
	{'filter_string':'"csdap-maxar-delivery","css/nga/GE01/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt'},
	{'filter_string':'"csdap-maxar-delivery","css/nga/WV01/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt'},
	{'filter_string':'"csdap-maxar-delivery","css/nga/WV02/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt'},
	{'filter_string':'"csdap-maxar-delivery","css/nga/WV03/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt'},
	{'filter_string':'"csdap-maxar-delivery","css/nga/WV04/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt'}
]

# Filter the Input
def filter_lines_in_file(file_path="", filter_string='DEFAULT_FILTER_STRING'):
	print(f'')
	print(f'About to filter lines from File: {file_path}')
	print(f'  Using Filter String: {filter_string}')

	matching_lines 			= []
	counter__total_lines 	= 0


	try:
		with open(file_path, 'r') as file:
			# Iterate through each line in the file
			for line in file:
				# Check the filter_string is in the line
				if filter_string in line:
					matching_lines.append(line.strip()) # Add this line to the return object without new line characters.
				#
				# Increment the counter.
				counter__total_lines = counter__total_lines + 1
	except FileNotFoundError:
		print(f'File not found: {file_path}')
	except Exception as e:
		print(f'An error occured: {e}')

	num_of_lines_to_return = len(matching_lines)
	
	print(f'')
	print(f'Finished processing {file_path}')
	print(f'  Filtered {counter__total_lines} total lines')
	print(f'  Keeping {num_of_lines_to_return} lines that passed the filter')
	print(f'')

	# Return the array
	return matching_lines

# Write the output
def write_filtered_output(file_path="", lines_to_write=[]):
	print(f'')
	print(f'About to write the filtered lines to the output file: {file_path}')
	print(f'  Num of line to write: {len(lines_to_write)}')
	print(f'')
	counter__lines_written = 0
	try:
		# Open the file in write mode, which replaces the file if it already exists.
		with open(file_path, 'w') as file:
			# Write each line in the array to the file.
			for line in lines_to_write:
				file.write(line + '\n')
				counter__lines_written = counter__lines_written + 1
		print(f'Successfully wrote to file: {file_path}')
		print(f'  Number of lines written: {counter__lines_written}')
	except Exception as e:
		print(f'An error occured: {e}')

# Main Entry Point
def main():
	print(f'main:  STARTED')
	datetime__START = datetime.datetime.utcnow()
	print(f'')
	print(f'Filtering lists...')
	print(f'')
	print(f'Settings Items:')
	print(f'  SETTINGS__Input_File:     {SETTINGS__Input_File}')
	print(f'  SETTINGS__Output_Objects: {SETTINGS__Output_Objects}')
	print(f'')
	#
	for output_obj in SETTINGS__Output_Objects:
		print(f'---------------------------------------------------------------')
		current_filtered_lines_list = filter_lines_in_file(file_path=SETTINGS__Input_File, filter_string=output_obj['filter_string'])
		write_filtered_output(file_path=output_obj['out_file'], lines_to_write=current_filtered_lines_list)
		print(f'---------------------------------------------------------------')
	#	
	datetime__END = datetime.datetime.utcnow()
	total_time__str = str(datetime__END-datetime__START)
	print(f'main:  Reached the End  -- Total Execution Time: {total_time__str}')

	

main()



# # Output from running this
# 
#
# ➜  mcp_MAXAR_deletes__q4_2024 python step_02__filter_lists.py
# main:  STARTED

# Filtering lists...

# Settings Items:
#   SETTINGS__Input_File:     manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   SETTINGS__Output_Objects: [{'filter_string': '"csdap-maxar-delivery","css/nga/GE01/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt'}, {'filter_string': '"csdap-maxar-delivery","css/nga/WV01/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt'}, {'filter_string': '"csdap-maxar-delivery","css/nga/WV02/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt'}, {'filter_string': '"csdap-maxar-delivery","css/nga/WV03/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt'}, {'filter_string': '"csdap-maxar-delivery","css/nga/WV04/1B/', 'out_file': 'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt'}]

# ---------------------------------------------------------------

# About to filter lines from File: manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Using Filter String: "csdap-maxar-delivery","css/nga/GE01/1B/

# Finished processing manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Filtered 183106060 total lines
#   Keeping 13383320 lines that passed the filter


# About to write the filtered lines to the output file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt
#   Num of line to write: 13383320

# Successfully wrote to file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt
#   Number of lines written: 13383320
# ---------------------------------------------------------------
# ---------------------------------------------------------------

# About to filter lines from File: manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Using Filter String: "csdap-maxar-delivery","css/nga/WV01/1B/

# Finished processing manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Filtered 183106060 total lines
#   Keeping 40729489 lines that passed the filter


# About to write the filtered lines to the output file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt
#   Num of line to write: 40729489

# Successfully wrote to file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt
#   Number of lines written: 40729489
# ---------------------------------------------------------------
# ---------------------------------------------------------------

# About to filter lines from File: manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Using Filter String: "csdap-maxar-delivery","css/nga/WV02/1B/

# Finished processing manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Filtered 183106060 total lines
#   Keeping 79638458 lines that passed the filter


# About to write the filtered lines to the output file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt
#   Num of line to write: 79638458

# Successfully wrote to file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt
#   Number of lines written: 79638458
# ---------------------------------------------------------------
# ---------------------------------------------------------------

# About to filter lines from File: manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Using Filter String: "csdap-maxar-delivery","css/nga/WV03/1B/

# Finished processing manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Filtered 183106060 total lines
#   Keeping 36696704 lines that passed the filter


# About to write the filtered lines to the output file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt
#   Num of line to write: 36696704

# Successfully wrote to file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt
#   Number of lines written: 36696704
# ---------------------------------------------------------------
# ---------------------------------------------------------------

# About to filter lines from File: manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Using Filter String: "csdap-maxar-delivery","css/nga/WV04/1B/

# Finished processing manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt
#   Filtered 183106060 total lines
#   Keeping 93754 lines that passed the filter


# About to write the filtered lines to the output file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt
#   Num of line to write: 93754

# Successfully wrote to file: step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt
#   Number of lines written: 93754
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:07:43.008125
# ➜  mcp_MAXAR_deletes__q4_2024 

