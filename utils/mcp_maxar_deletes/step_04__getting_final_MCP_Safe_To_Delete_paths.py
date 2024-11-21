# step_04__getting_final_MCP_Safe_To_Delete_paths.py

# python step_04__getting_final_MCP_Safe_To_Delete_paths.py

import datetime


# The array to hold each config object.
# # 3 file paths, 2 inputs, and 1 output.
# # 2 file inputs are used, 
# # The first file input is the main list that will be filtered,
# # The second file input is the list used to filter against the first
# # The file output is where the filtered list will end up.
#
SETTINGS__Processing_Objects = [
	# {'in_file__MCP': '', 'in_file__NGAP': '', 'out_file__MCP': ''}
	# Note, there are not duplicates objects here -- For WV03 and WV04, the MCP lists are combined, but the NGAP lists are separate.
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/GE01_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV01_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
]

# # Settings with only a single item (useful for debugging and figuring out the timing)
# SETTINGS__Processing_Objects = [
# 	# {'in_file__MCP': '', 'in_file__NGAP': '', 'out_file__MCP': ''}
# 	# Note, there are not duplicates objects here -- For WV03 and WV04, the MCP lists are combined, but the NGAP lists are separate.
# 	{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# ]

SETTINGS__Add_Formatting_To_Final_Output = True


# This function adds final output text to each string so that we can have it in the exact format for the Batch Job that will use it!
# Actually, this function adds formating to one string at a time, but it is called for every string if the setting 'SETTINGS__Add_Formatting_To_Final_Output' is set to True
def add_formatting_to_string(in_str=''):
	#ret_str = f'ADD_FORMATTING__{in_str}'
	ret_str = f'csdap-maxar-delivery,{in_str}' 		# This adds the bucket name and a comma in front of an input Granule Path String
	return ret_str

# Open a (text) file, read each line into an array and return the array
def open_file_and_load_lines_into_array(in_file_path=''):
	ret_array = []
	with open(in_file_path, 'r') as in_file:
		for line in in_file:
			ret_array.append(line)
	return ret_array

# The Heavy Lifting
#
def process_lists(process_obj={}):
	
	# Lists
	in_file__MCP__Granule_Paths_List 			= []  	# Array of Items that Look like this:  # css/nga/WV04/1B/2018/024/WV04_318ca2f5-facd-407b-9e49-ae9fc7b6d4f8-inv_X1BS_059102578120_01/WV04_20180124003728_318ca2f5-facd-407b-9e49-ae9fc7b6d4f8-inv_18JAN24003728-P1BS-059102578120_01_P002
	in_file__NGAP__Granule_List 				= [] 	# Array of Items that Look like this:  # WV04_20180117002416_6e233411-599c-4135-8f2d-943a4a0b1528-inv_18JAN17002416-P1BS-059102602170_01_P001
	out_file__MCP__Filtered_Granule_Paths_List 	= []    # Array of Items that look like the in_file__MCP__Granule_Paths_List but only contain items where the GranuleID existed in the NGAP list as well.
	#
	# Counters
	counter__outer_loop_iterations 				=  	0
	counter__total_inner_loop_iterations 		=	0
	#
	# Reporting in progress.
	frequency_of_reporting_inner_loops 			= 100000000 # 10000000 #1000000 # 100000 
	counter__num_of_inner_loop_reports 			= 0 
	#
	num_of_granule_paths_found = 0

	# Dictionary Method
	ngap_granule_ids__not_found = [] 			# List of Granule IDs that are not found at all

	
	try:
		# {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/GE01_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'},
		in_file__MCP 	= process_obj['in_file__MCP']
		in_file__NGAP 	= process_obj['in_file__NGAP']
		out_file__MCP 	= process_obj['out_file__MCP']

		# CONTINUE HERE ---- OPEN THE FILES,, DO THE CHECKING LOOPS, THEN OUTPUT THE NEW LIST!

		# Open the two input files, load them in memory, apply the filtering, write the output of specific items that passed the filter
		

		# Open in_file__MCP
		try:
			in_file__MCP__Granule_Paths_List = open_file_and_load_lines_into_array(in_file_path=in_file__MCP)
		except Exception as e:
			print(f'process_lists: ERROR: Error Loading MCP Granule Paths List.  System Message: {e}')
			
		
		# Open in_file__NGAP
		try:
			in_file__NGAP__Granule_List = open_file_and_load_lines_into_array(in_file_path=in_file__NGAP)
		except Exception as e:
			print(f'process_lists: ERROR: Error Loading NGAP Granule IDs List.  System Message: {e}')
		
		# Process the List
		try:
			# I need a theoretical max inner range to be able to estimate percent progress.
			theoretical_max_inner_loops 				= len(in_file__MCP__Granule_Paths_List) * len(in_file__NGAP__Granule_List)
	
			# Prevent Dividing by zero on errors further down below.
			if(theoretical_max_inner_loops < 1):
				theoretical_max_inner_loops = 1






			## Dictionary Method
			#
			# Create a Dictionary and do some interesting stuff with Keys and values and flags to iterate the list less often
			#
			# Example from NGAP Safe To Delete List (Granule ID Only): 	WV04_20181218053031_b913f7ec-1a50-4fb1-8e66-0b32fcaeee21-inv_18DEC18053031-P1BS-059420283030_01_P008
			# Example from MCP Path Item: 								css/nga/WV04/1B/2018/052/WV04_90fce728-fbec-40c1-bd39-74e524eac58c-inv_X1BS_059102542080_01/WV04_20180221235737_90fce728-fbec-40c1-bd39-74e524eac58c-inv_18FEB21235737-M1BS-059102542080_01_P002 			
			# The reason I need to do this at all is because: The Info we need to keep is located in the MIDDLE of the URL and did not make it to the NGAP server, so that info in the original path is not part of the data after ingestion
			#
			# Detailed Description of Dictionary Method
			#
			# 	Create a dictionary
			# 		Use the Granule IDs as Keys
			# 			Iterate MCP list, 
			# 				Filter out to just the granule_id, 
			# 				Add every MCP path to 			['granule_id']['path'] 					(so this is as a sub key'd value)
			# 				Set a flag to False by default 	['granule_id']['is_safe_to_delete']  	// Defaulting to false
			# 			Iterate NGAP list
			# 				Check to see if the granule_id already has a key in the dictionary
			# 					If it does, set the flag ['granule_id']['is_safe_to_delete'] to True
			# 					If it does not, Add this granule_id to a separate array called 'ngap_granule_id__not_found'
			# 			After the above processing
			# 				Get the list of Keys from the Dictionary
			# 				Iterate that list of keys
			# 					Check the current Item property dictionary['granule_id']['is_safe_to_delete'] to see if it is True or False
			# 					If it is True
			# 						Append dictionary['granule_id']['path'] to the final safe to delete paths list
			# 					If it is False
			# 						Do nothing, just pass on this item (this means it is NOT safe to delete)
			# 		Last Step (true for all methods)
			# 			Write this list to a file
			#
			#
			# Each Key here will represent only a granule ID
			main_dict = {}
			
			# Add Initial MCP list as keys
			#
			# BenchMark Test: This for loop execution time for the largest dataset was: 0:00:11.454076 	(about 12 seconds)
			for mcp_granule_path in in_file__MCP__Granule_Paths_List:

				# Split the MCP Path down to JUST the granule ID 	# my_str.split('/')[-1]
				mcp_granule_path__Granule_ID_ONLY = mcp_granule_path.split('/')[-1]

				# Create a new sub dictionary object to hold the info
				new_dict_sub_object 							= {'path':mcp_granule_path, 'is_safe_to_delete': False} #, 'has_path': True}

				# Add a new key (using only the Granule ID as the key) and add the new sub dictionary object to that key
				main_dict[mcp_granule_path__Granule_ID_ONLY] 	= new_dict_sub_object

			# See how many keys we have and get the list of keys into a separate object outside of the for loops.
			main_dict_keys 				= list(main_dict.keys())
			num_of_MCP_GranuleID_keys 	= len(main_dict_keys) # len(main_dict.keys())
			#
			print(f'(num_of_MCP_GranuleID_keys):       {num_of_MCP_GranuleID_keys} ')

			# And output a DEBUG Statement Here at this point
			#
			# print(f'')
			# print(f'(DEBUG): (num_of_MCP_GranuleID_keys):       {num_of_MCP_GranuleID_keys} ')
			# print(f'(DEBUG): (list(main_dict.keys())[75]):      {list(main_dict.keys())[75]} ')
			# print(f'')
			# print(f'(DEBUG): Converting the original list into a set and then checking the count..')
			# len_of_unique_MCP_Granule_Paths_List = len(list(set(in_file__MCP__Granule_Paths_List)))
			# print(f'(DEBUG):     (len_of_unique_MCP_Granule_Paths_List): {len_of_unique_MCP_Granule_Paths_List}')
			# print(f'')



			# Add Debug Exit Here for testing!		
			#
			# 	# Increment the outer loop
			# 	counter__outer_loop_iterations = counter__outer_loop_iterations + 1
			# 	#if(counter__outer_loop_iterations > 322):
			# 	if(counter__outer_loop_iterations > 100):
			# 		print(f'(DEBUG):  Found {num_of_granule_paths_found} granule paths...')
			# 		print(f'(DEBUG):  ...Breaking out of method 2 at outer loop count {counter__outer_loop_iterations}, so we can calculate the time for a fraction of the data')
			# 		return

			# # Need to make this further efficient.. I can just overwrite objects if they exist already.
			# # Iterate the GranuleID List from NGAP
			# counter__ngap_loops 	= 0
			# counter__found 			= 0
			# # This loop only takes about 2 seconds to do 3 items (but I need to test it a bit more)
			# # 10 seconds to find 101 granules.
			# for ngap_granule_id in in_file__NGAP__Granule_List:
			# 	if(ngap_granule_id in main_dict_keys):
			# 		counter__found = counter__found + 1
			# 	#
			# 	if(counter__found > 101):
			# 		print(f'(DEBUG): (counter__found): {counter__found}.  EXITING!')
			# 		return
			# 	#
			# 	counter__ngap_loops = counter__ngap_loops + 1
			# 	#
			# 	# if(counter__ngap_loops > 2):
			# 	# 	print(f'(DEBUG): (counter__ngap_loops): {counter__ngap_loops}.  EXITING NOW FOR TIMING PURPOSSES')
			# 	# 	return
			# print(f'(DEBUG): (counter__found): {counter__found}')

			# # More Efficient NGAP Iteration Method than the one that uses the .keys() and if statement check.
			# BenchMark: 
			# # 2 seconds and did find the first 4 granule.
			# # 2 seconds and did find the first 102 granules also (So the error on time calc here might just be a variance loading the lists!)
			# # 7 Seconds and found ALL NGAP Granules
			#
			#
			# Example:
			# main_dict[mcp_granule_path__Granule_ID_ONLY] 
			# # {'path':mcp_granule_path, 'is_safe_to_delete': False} #, 'has_path': True}
			counter__ngap_loops 				= 0
			counter__Found_Safe_To_Delete_Item 	= 0 
			counter__NOT_FOUND 					= 0
			for ngap_granule_id in in_file__NGAP__Granule_List:
				try:
					main_dict[ngap_granule_id]['is_safe_to_delete'] = True
					counter__Found_Safe_To_Delete_Item = counter__Found_Safe_To_Delete_Item + 1
				except:
					ngap_granule_ids__not_found.append(ngap_granule_id)
					counter__NOT_FOUND = counter__NOT_FOUND + 1

				counter__ngap_loops = counter__ngap_loops + 1
				
				# Debugging and Time Calcs
				#
				# #if(counter__ngap_loops > 3):
				# if(counter__Found_Safe_To_Delete_Item > 101):
				# 	print(f'(DEBUG): (counter__ngap_loops):                 {counter__ngap_loops}.  ')
				# 	print(f'(DEBUG): (counter__Found_Safe_To_Delete_Item):  {counter__Found_Safe_To_Delete_Item}.  ')
				# 	print(f'(DEBUG): (counter__NOT_FOUND):                  {counter__NOT_FOUND}.  ')
				# 	print(f'(DEBUG): EXITING!')
				# 	return
			print(f'')
			print(f'(NGAP_Loop_Done): (counter__ngap_loops):                 {counter__ngap_loops}')
			print(f'(NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  {counter__Found_Safe_To_Delete_Item}')
			print(f'(NGAP_Loop_Done): (counter__NOT_FOUND):                  {counter__NOT_FOUND}')
			print(f'')
			#
			# (NGAP_Loop_Done): (counter__ngap_loops):                 3111290  
			# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  3111290  
			# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0  
			#


			# Last Step - Examine all the Keys in the main_dict one by one and save the paths for the ones that have the proper flag set!
			#
			# Benchmark: about 1 second!  We were up to 17 seconds when executing up to this point... After this part: 18 Seconds... 
			#
			# For this step, just iterate all the dict keys and check to see if the 'is_safe_to_delete' flag has been modified.
			for granule_id_key in main_dict_keys:

				# Check to see if this current granule ID IS safe to delete!
				is_safe_to_delete = main_dict[granule_id_key]['is_safe_to_delete']
				if(is_safe_to_delete == True):
					# If it is safe to delete, append the path to the final output list!
					current_granule_path = main_dict[granule_id_key]['path']
					out_file__MCP__Filtered_Granule_Paths_List.append(current_granule_path)

			print(f'')
			print(f'(Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  {len(out_file__MCP__Filtered_Granule_Paths_List)}')
			print(f'')
			



			##############################################
			# OLDER METHODS (that were too inefficient)
			##############################################


			# ## This method takes 0:01:50.026468 time to find 101 granule paths out of millions
			# #
			# # Iterate the MCP Input List
			# #for mcp_granule_path in in_file__MCP__Granule_Paths_List:
			# for i, string in enumerate(in_file__MCP__Granule_Paths_List):
			#
			# 	# Inner Loop
			# 	if any(term in string for term in in_file__NGAP__Granule_List):
			# 		out_file__MCP__Filtered_Granule_Paths_List.append(i) 		# mcp_granule_path
			#
			# 		# Recount how many items we have
			# 		num_of_granule_paths_found = len(out_file__MCP__Filtered_Granule_Paths_List)
			#
			# 	# Increment the outer loop
			# 	counter__outer_loop_iterations = counter__outer_loop_iterations + 1
			# 	#if(counter__outer_loop_iterations > 322):
			# 	if(counter__outer_loop_iterations > 100):
			# 		print(f'(DEBUG):  Found {num_of_granule_paths_found} granule paths...')
			# 		print(f'(DEBUG):  ...Breaking out of method 2 at outer loop count {counter__outer_loop_iterations}, so we can calculate the time for a fraction of the data')
			# 		return

			# ## This method takes over 3 minutes to find 100 granules out of millions (TOO SLOW)
			# #
			# # Iterate the MCP Input List
			# for mcp_granule_path in in_file__MCP__Granule_Paths_List:
			#
			#	
			# 	# Iterate the GranuleID List from NGAP
			# 	for ngap_granule_id in in_file__NGAP__Granule_List:
			#		
			# 		# Check to see if the NGAP Granule ID appears in the MCP Granule Path
			# 		if (ngap_granule_id in mcp_granule_path):
			# 			# If the granule ID does appear in the Path, then save the Path for writing later
			# 			out_file__MCP__Filtered_Granule_Paths_List.append(mcp_granule_path)
			#
			# 		# Increment the inner loop counter
			# 		counter__total_inner_loop_iterations = counter__total_inner_loop_iterations + 1
			#
			#			
			#
			# 		# Reporting
			# 		if( (counter__total_inner_loop_iterations % frequency_of_reporting_inner_loops) == 0):
			# 			progress_percent 		= (counter__total_inner_loop_iterations / theoretical_max_inner_loops) * 100
			# 			progress_percent__str 	= "%.2f}" % progress_percent # Convert float to 2 decimal point string.
			# 			print(f'  Progress: ({progress_percent__str}) ( {counter__total_inner_loop_iterations} out of {theoretical_max_inner_loops} )')
			#		
			#			
			#			
			# 			print(f'      OUTER ITEM: (mcp_granule_path):         {mcp_granule_path}')
			# 			print(f'      INNER ITEM: (ngap_granule_id):          {ngap_granule_id}')
			# 			print(f'      (counter__total_inner_loop_iterations): {counter__total_inner_loop_iterations}')
			# 			print(f'      (counter__outer_loop_iterations):       {counter__outer_loop_iterations}')
			# 			print(f'      Current Num of Granules Found so far:   {len(out_file__MCP__Filtered_Granule_Paths_List)}')
			#			
			# 		# Debugging and timing - Figuring out how long it will take to iterate one of these lists.
			# 		#if(counter__total_inner_loop_iterations > 1000000): 	# 1 Million
			# 		#if(counter__total_inner_loop_iterations > 10000000): 	# 10 Million
			# 		#if(counter__total_inner_loop_iterations > 100000000): 	# 100 Million
			# 		if(counter__total_inner_loop_iterations > 1000000000): 	# 1 Billion
			# 			print(f'')
			# 			print(f'......')
			# 			print(f'  BREAKING OUT because I want to see how long a specific number of inner iterations takes:')
			# 			return
			#
			#	
			# 	# Incrementing the outer loop counter 
			# 	counter__outer_loop_iterations = counter__outer_loop_iterations + 1
			
		except Exception as e:
			print(f'process_lists: ERROR: Error while Actually processing and filtering lists.  System Message: {e}')
			pass
		
		# Write the Output File
		try:
			# Write the Output to the Out File
			out_file__MCP__Filtered_Granule_Paths_List

			# Save the new list to a new file at 'out_file' (overwriting if it already exists)
			with open(out_file__MCP, 'w') as out_file:
				# Iterate each line in the list. 
				for line_to_write in out_file__MCP__Filtered_Granule_Paths_List:

					# Add Formatting if the setting is set to do so.
					if(SETTINGS__Add_Formatting_To_Final_Output == True):
						line_to_write = add_formatting_to_string(in_str=line_to_write)

					# Write the line and a newline char ('\n') at the end
					#out_file.write(line_to_write+'\n')
					out_file.write(line_to_write)

			pass
		except Exception as e:
			print(f'process_lists: ERROR: Error Writing Final Output MCP Safe To Delete Granule Paths List.  System Message: {e}')

		
	
	except Exception as e:
		print(f'process_lists: ERROR (top level): An error occured: {e}.  Input Object: (process_obj): {process_obj}')
		pass

	# Output the Counts
	print(f'')
	print(f'Item Counts (After Processing)')
	print(f'    in_file__MCP__Granule_Paths_List:             {len(in_file__MCP__Granule_Paths_List)}')
	print(f'    in_file__NGAP__Granule_List:                  {len(in_file__NGAP__Granule_List)}')
	print(f'    out_file__MCP__Filtered_Granule_Paths_List:   {len(out_file__MCP__Filtered_Granule_Paths_List)}')
	print(f'      Total Inner Loop Iterations:   			    {counter__total_inner_loop_iterations}')
	counter__total_inner_loop_iterations



# Entry Point
def main():
	print(f'main:  STARTED')
	datetime__START = datetime.datetime.utcnow()

	print(f'')
	print(f'Using OLD_NGAP MAXAR lists to Filter MCP Single Granule Paths List down to the MCP Safe_To_Delete Lists of single Granule Paths...')
	print(f'')
	print(f'Settings Items:')
	print(f'  SETTINGS__Processing_Objects:     {SETTINGS__Processing_Objects}')
	#
	for process_obj in SETTINGS__Processing_Objects:
		print(f'---------------------------------------------------------------')
		print(f'About to Process Item: (process_obj): {process_obj}')
		#print(f'TODO -- Finish writing this function')
		process_lists(process_obj=process_obj)
		print(f'---------------------------------------------------------------')

	datetime__END = datetime.datetime.utcnow()
	total_time__str = str(datetime__END-datetime__START)
	print(f'main:  Reached the End  -- Total Execution Time: {total_time__str}')

main()




# Figuring out how long this script takes to run
#
# # Loading all of the settings and loading all of the data into memory, but NOT YET Actually Processing the loop and the nested loop.
# main:  Reached the End  -- Total Execution Time: 0:00:05.889644
#
# # Running a single dataset up to 1 million inner loop iterations.
# ➜  mcp_MAXAR_deletes__q4_2024 python step_04__getting_final_MCP_Safe_To_Delete_paths.py
# main:  STARTED
# Using OLD_NGAP MAXAR lists to Filter MCP Single Granule Paths List down to the MCP Safe_To_Delete Lists of single Granule Paths...
# Settings Items:
#   SETTINGS__Processing_Objects:     [{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}]
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
#   BREAKING OUT because I want to see how long 1 million inner iterations takes:
#       OUTER ITEM: (mcp_granule_path):         css/nga/WV02/1B/2021/293/WV02_10300100C879D000_P1BS_505826846030_01/WV02_20211020032708_10300100C879D000_21OCT20032708-P1BS-505826846030_01_P009
#       INNER ITEM: (ngap_granule_id):          WV02_20200918100842_10300100AD4B6E00_20SEP18100842-M1BS-504711927020_01_P006
#       (counter__total_inner_loop_iterations): 1000001
#       (counter__outer_loop_iterations):       0
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:00:03.163323
#
#
# # For 10,000,000 
# Progress: (0.00}) ( 10000000 out of 32169683872690 )
# main:  Reached the End  -- Total Execution Time: 0:00:04.776866
#
#
# # For 100,000,000
# Progress: (0.00}) ( 100000000 out of 32169683872690 )
# OUTER ITEM: (mcp_granule_path):         css/nga/WV02/1B/2013/215/WV02_1030010025555200_P1BS_506721258040_01/WV02_20130803003409_1030010025555200_13AUG03003409-P1BS-506721258040_01_P010
# INNER ITEM: (ngap_granule_id):          WV02_20180531110134_103001007E769200_18MAY31110134-M1BS-502225839100_01_P001
# (counter__total_inner_loop_iterations): 100000000
# (counter__outer_loop_iterations):       32
# Current Num of Granules Found so far:   10
# main:  Reached the End  -- Total Execution Time: 0:00:20.427198
#
#
# # Method 1 -- For 1,000,000,000  	(Method 1 - Got to 321 Granules)
# Progress: (0.00}) ( 1000000000 out of 32169683872690 )
# OUTER ITEM: (mcp_granule_path):         css/nga/WV02/1B/2020/304/WV02_10300100B0738400_M1BS_504825608050_01/WV02_20201030110450_10300100B0738400_20OCT30110450-M1BS-504825608050_01_P002
# INNER ITEM: (ngap_granule_id):          WV02_20200521051728_10300100A73CFC00_20MAY21051728-M1BS-504321594010_01_P001
# (counter__total_inner_loop_iterations): 1000000000
# (counter__outer_loop_iterations):       321
# Current Num of Granules Found so far:   101
# main:  Reached the End  -- Total Execution Time: 0:02:56.797226

# # Method 2 - Up to 323 granules (to match a previous test)
# ➜  mcp_MAXAR_deletes__q4_2024 python step_04__getting_final_MCP_Safe_To_Delete_paths.py
# main:  STARTED
# Using OLD_NGAP MAXAR lists to Filter MCP Single Granule Paths List down to the MCP Safe_To_Delete Lists of single Granule Paths...
# Settings Items:
#   SETTINGS__Processing_Objects:     [{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}]
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (DEBUG):  Found 101 granule paths...
# (DEBUG):  ...Breaking out of method 2 at outer loop count 323, so we can calculate the time for a fraction of the data
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:01:50.026468

# # Method 2 -- Again, but only up to 101 granules (to actually match Method 1's trial)



# # Dictionary Method Output, All the way to a final output! (WV02_MSI_L1B)
#
#➜  mcp_MAXAR_deletes__q4_2024 python step_04__getting_final_MCP_Safe_To_Delete_paths.py
# main:  STARTED
#
# Using OLD_NGAP MAXAR lists to Filter MCP Single Granule Paths List down to the MCP Safe_To_Delete Lists of single Granule Paths...
#
# Settings Items:
#   SETTINGS__Processing_Objects:     [{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}]
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       10329679 
#
# (NGAP_Loop_Done): (counter__ngap_loops):                 3111290
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  3111290
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0
#
#
# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  3111290
#
#
# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             10339661
#     in_file__NGAP__Granule_List:                  3111290
#     out_file__MCP__Filtered_Granule_Paths_List:   3111290
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:00:24.016042
# ➜  mcp_MAXAR_deletes__q4_2024 




# # For Reference, Here are the config settings from Step 03
#
# SETTINGS__is_run__OLD_NGAP_MAXAR 		= False #True
# SETTINGS__MODE__OLD_NGAP_MAXAR_Paths 	= [
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'},
# 	{'in_file':'step_03__GettingGranuleIDs/last_time__safe_to_delete_lists/safe_to_delete_lists__RAW/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__csdap-cumulus-prod-public.csv', 'out_file': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt'}
# ]
#
#
# # Settings for MCP_MAXAR
# SETTINGS__is_run__MCP_MAXAR 	= True
# SETTINGS__MODE__MCP_MAXAR_Paths = [
# 	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__GE01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt'},
# 	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV01_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt'},
# 	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV02_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt'},
# 	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV03_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt'},
# 	{'in_file':'step_02__filtering_large_manifests_down/filtered_lists/MCP__Delivery_Bucket__WV04_1B__BOTH.txt', 'out_file': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt'}
# ]











# Final Output (Before adding the last bit of formatting code)
#
# ➜  mcp_MAXAR_deletes__q4_2024 python step_04__getting_final_MCP_Safe_To_Delete_paths.py
# main:  STARTED

# Using OLD_NGAP MAXAR lists to Filter MCP Single Granule Paths List down to the MCP Safe_To_Delete Lists of single Granule Paths...

# Settings Items:
#   SETTINGS__Processing_Objects:     [{'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/GE01_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV01_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}, {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}]
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__GE01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/GE01_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/GE01_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       1819068 

# (NGAP_Loop_Done): (counter__ngap_loops):                 722623
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  722623
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  722623


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             1845101
#     in_file__NGAP__Granule_List:                  722623
#     out_file__MCP__Filtered_Granule_Paths_List:   722623
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV01_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV01_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV01_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       5074494 

# (NGAP_Loop_Done): (counter__ngap_loops):                 5023086
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  5023086
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  5023086


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             5078347
#     in_file__NGAP__Granule_List:                  5023086
#     out_file__MCP__Filtered_Granule_Paths_List:   5023086
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV02_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV02_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV02_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       10329679 

# (NGAP_Loop_Done): (counter__ngap_loops):                 3111290
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  3111290
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  3111290


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             10339661
#     in_file__NGAP__Granule_List:                  3111290
#     out_file__MCP__Filtered_Granule_Paths_List:   3111290
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       4626037 

# (NGAP_Loop_Done): (counter__ngap_loops):                 1882712
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  1882712
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  1882712


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             4627513
#     in_file__NGAP__Granule_List:                  1882712
#     out_file__MCP__Filtered_Granule_Paths_List:   1882712
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV03_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV03_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV03_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       4626037 

# (NGAP_Loop_Done): (counter__ngap_loops):                 2515801
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  2515801
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  2515801


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             4627513
#     in_file__NGAP__Granule_List:                  2515801
#     out_file__MCP__Filtered_Granule_Paths_List:   2515801
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_MSI_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_MSI_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       12705 

# (NGAP_Loop_Done): (counter__ngap_loops):                 6753
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  5950
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  803


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  5950


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             12705
#     in_file__NGAP__Granule_List:                  6753
#     out_file__MCP__Filtered_Granule_Paths_List:   5950
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# ---------------------------------------------------------------
# About to Process Item: (process_obj): {'in_file__MCP': 'step_03__GettingGranuleIDs/MCP_Single_Granule_Only_Lists/MCP__Delivery_Bucket__Path_To_Granule__WV04_1B__BOTH.txt', 'in_file__NGAP': 'step_03__GettingGranuleIDs/OLD_NGAP_Single_Granule_Only_Lists/WV04_PAN_L1B___1__SAFE_TO_DELETE__OLD_NGAP__GRANULE_ONLY_LIST.txt', 'out_file__MCP': 'step_04__Get_Final_MCP_SafeToDelete_Lists/MCP_Single_Granule_PAths_Safe_To_Delete/WV04_PAN_L1B__Safe_To_Delete_MCP_Granule_Paths.txt'}
# (num_of_MCP_GranuleID_keys):       12705 

# (NGAP_Loop_Done): (counter__ngap_loops):                 6753
# (NGAP_Loop_Done): (counter__Found_Safe_To_Delete_Item):  6753
# (NGAP_Loop_Done): (counter__NOT_FOUND):                  0


# (Filtering_Done): (len(out_file__MCP__Filtered_Granule_Paths_List)):                  6753


# Item Counts (After Processing)
#     in_file__MCP__Granule_Paths_List:             12705
#     in_file__NGAP__Granule_List:                  6753
#     out_file__MCP__Filtered_Granule_Paths_List:   6753
#       Total Inner Loop Iterations:   			    0
# ---------------------------------------------------------------
# main:  Reached the End  -- Total Execution Time: 0:00:49.518011
# ➜  mcp_MAXAR_deletes__q4_2024   

