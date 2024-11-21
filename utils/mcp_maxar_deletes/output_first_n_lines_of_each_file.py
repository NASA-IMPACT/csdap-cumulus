# output_first_n_lines_of_each_file.py

# python output_first_n_lines_of_each_file.py


# The point of this file is to output the first 5 lines of each file, just so we can see the sample

SETTING__files_collection = [
'manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_CBA_DR_COMPLETE_MANIFEST_FILE_LIST__2024-10-21.txt',
'manifest_work_area/cached_full_list_of_bucket_key_paths/complete__MCP_COMPLETE_MANIFEST_FILE_LIST__2024-10-19.txt',
'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt',
'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt',
'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_Pan_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv',
'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv'
]


def print_first_n_lines_from_file(file_path="", n=5):
	print(f'')
	print(f'About to read {n} lines from File: {file_path}')
	try:
		with open(file_path, 'r') as file:
			# Read the first 5 lines
			#for i in range(5):
			for i in range(n):
				line = file.readline()
				if not line:
					print(f'We seemed to have reached the end of this file before {n} lines!')
					break
				print(f'  Line {i}: {line.strip()}')
	except FileNotFoundError:
		print(f'File not found: {file_path}')
	except Exception as e:
		print(f'An error occured: {e}')
	print(f'')



def main():
	print(f'output_first_5_lines_of_each_file: STARTED')

	print(f'')
	print(f'Current File Paths (SETTING__files_collection): {SETTING__files_collection}')
	print(f'')

	for file_path in SETTING__files_collection:
		#print(f'file_path: {file_path}')
		print_first_n_lines_from_file(file_path=file_path, n=10)

	print(f'output_first_5_lines_of_each_file: Reached the End')
	


main()