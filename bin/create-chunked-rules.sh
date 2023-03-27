#!/bin/bash

#create-chunked-rules.sh

# # Example Usage: (Make a file for each year for a 5 year range)
# sh create-chunked-rules.sh 2014-01-01 2019-01-01 P1Y demo/app/stacks/cumulus/resources/rules/WV03_MSI_L1B/v1/WV03_MSI_L1B___1__template.json out/dir/path ___1_
# # Output:
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2015.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2016.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2017.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2018.json

# # Example Usage: (Make a file for each month for a 4 month)
# sh create-chunked-rules.sh 2014-01-01 2014-05-01 P1M demo/app/stacks/cumulus/resources/rules/WV03_MSI_L1B/v1/WV03_MSI_L1B___1__template.json out/dir/path ___1_
# # Output:
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_01.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_02.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_03.json
# ....
# ....
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_18.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_19.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_20.json

# # Example Usage: (Make a file for each day for a 2 and a half month range)
# sh create-chunked-rules.sh 2014-01-01 2014-03-21 P1D demo/app/stacks/cumulus/resources/rules/WV03_MSI_L1B/v1/WV03_MSI_L1B___1__template.json out/dir/path ___1_
# # Output:
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_01.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_02.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_01_03.json
# ....
# ....
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_18.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_19.json
# Just wrote file: out/dir/path/WV03_MSI_L1B___1_2014_03_20.json



# Settings
default_base_name_append_suffix="___1_"
default_output_subdir="default_output_dir/dataset"



# # Check for jq lib
# The command -v jq command checks if the jq command is available in the system's path. The &> /dev/null redirects both standard output and error output to the null device so that the output is not printed to the console.
# The if statement checks if the jq command was found (command -v returns a non-zero exit status if the command is not found), and prints a message accordingly.
#has_jq=false
if command -v jq &> /dev/null; then
    echo "Required lib: jq was found on this system"
    #has_jq=true
else
    echo "Required lib: jq was not found on this system. 'jq' is required to run this script."
    exit 1
fi


# Check the required input params.

# Check if the required input parameters are provided through command line arguments
if [ $# -lt 4 ]; then
	# Prompt the user to enter input parameters
    echo "Did not detect all required command line parameters.  Please enter them one at a time below."
    echo "Please enter the required input parameters:"
    read -p "            date_start (Format YYYY-MM-DD): " date_start
    read -p "              date_end (Format YYYY-MM-DD): " date_end
    read -p "                  file_time_step (ex: P1Y): " file_time_step
    read -p "in_template_file_path (path to .json file): " in_template_file_path
    read -p "output_subdir (${default_output_subdir}): " output_subdir
    read -p "base_name_append_suffix (${default_base_name_append_suffix}): " base_name_append_suffix
else
	echo "Detected at least 4 required command line parameters."
    date_start=$1
    date_end=$2
    file_time_step=$3
    in_template_file_path=$4
    output_subdir=$5
    base_name_append_suffix=$6
fi

# Check if all input parameters have been entered
if [[ -z "${date_start}" || -z "${date_end}" || -z "${file_time_step}" || -z "${in_template_file_path}" ]]; then
    echo "Please enter all required input parameters to continue.   date_start format must be: YYYY-MM-DD"
    echo "    date_start: format must be: YYYY-MM-DD"
    echo "    date_end: format must be: YYYY-MM-DD"
    echo "    file_time_step: is the step between files, for example, P1Y means there will be one file generated per year (Last character can be: D, M, Y)"
    echo "    in_template_file_path: is the path to the json file that is used as a template for generating the other files"
    echo "    (optional) output_subdir: is the path to the directory where all the output json files will be written"
    echo "    (optional) base_name_append_suffix: is the part of the output file names between the collection name and the date."
    exit 1
fi


# VALIDATION

# Check if date_start and date_end is in the correct format
if ! [[ ${date_start} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid date format for date_start. Please use YYYY-MM-DD format."
  exit 1
fi
if ! [[ ${date_end} =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid date format for date_end. Please use YYYY-MM-DD format."
  exit 1
fi

# Check if time step is in the correct format
if ! [[ ${file_time_step} =~ ^P[0-9]{1,3}[DMY]$ ]]; then
  echo "Invalid time step format. Please use P<number><capital letter> format.  The number can be 1, 2 or 3 digits and the letter can only be one of the following: D, M, Y. (The letters represent which period you are selecting from the choices: 'Day', 'Month', and 'Year')"
  exit 1
fi

# Check to see if the in_template_file_path variable was entered.
if [ -z "$in_template_file_path" ]; then
  echo "Error: in_template_file_path variable cannot be blank."
  exit 1
fi

# Check if the file exists
if [ ! -f "$in_template_file_path" ]; then
  echo "Error: File not found: $in_template_file_path"
  exit 1
fi


# Optional Parameter - output_subdir
# Check to see if the output_subdir variable was entered.  If it was not, then use the default subdir
if [ -z "$output_subdir" ]; then
  output_subdir=$default_output_subdir
fi

# Optional Parameter - base_name_append_suffix
# Check to see if the base_name_append_suffix variable was entered.  If it was not, then use the default.
if [ -z "$base_name_append_suffix" ]; then
  base_name_append_suffix=$default_base_name_append_suffix
fi



# Echo the received inputs
echo ""
echo "Input Params"
echo "               (date_start): $date_start"
echo "                 (date_end): $date_end"
echo "           (file_time_step): $file_time_step"
echo "    (in_template_file_path): $in_template_file_path"

echo ""
echo "Settings"
echo "          (base_name_append_suffix): $base_name_append_suffix"
echo "                    (output_subdir): $output_subdir"



# parse the file_time_step to determine the interval
file_time_step_interval=$(echo $file_time_step | sed 's/[^0-9]//g')

# determine the unit of the file_time_step
file_time_step_unit=${file_time_step: -1}   # P1M turns into M

is_mac=false
if [[ "$OSTYPE" == "darwin"* ]]; then
  is_mac=true
fi


# Create the output subdirectory if it does not already exist
echo ""
if [[ ! -d "$output_subdir" ]]; then
  echo "Output Directory: ${output_subdir} was not found.  Creating it now."
  mkdir -p "$output_subdir"
else
  echo "Output Directory: ${output_subdir} was found."
fi


# Echo the derived variables
echo ""
echo "Derived Variables for getting the dates"
echo "    Time Step Interval:      (file_time_step_interval): $file_time_step_interval"
echo "    Time Step Unit:              (file_time_step_unit): $file_time_step_unit"
echo "    Running this on a Mac?:                   (is_mac): $is_mac"


# Read the input template JSON file into a variable
in_template_json=$(cat "$in_template_file_path")

# Extract the value of the "collection.name" parameter so we can name the files after this value.
json__collection_name=$(jq -r '.collection.name' "$in_template_file_path")
out_files_base_name="${json__collection_name}${base_name_append_suffix}"   # some_string + ___ # some_string___


# Echo the derived variables for Building the template files
echo ""
echo "Derived Variables for Building the template files"
echo "    Collection Name:      (json__collection_name): $json__collection_name"
echo "    File Base Name:         (out_files_base_name): $out_files_base_name"
echo "    Template JSON:             (in_template_json): $in_template_json"



# Function for creating each of these files.
# Expected Inputs: $date $next_date $file_time_step_unit $out_files_base_name $output_subdir $in_template_file_path
make_output_file() {
  #echo "$1 and $2 and $3"  # 2015-01-01 and 2016-01-01 and Y

  # String to add to the time variable
  time_suffix="T00:00:00Z"

  date_str_start=$1
  date_str_end=$2
  # Use the first date as the filename part
  filename_suffix_builder=""
  year_str=${date_str_start:0:4}
  month_str=${date_str_start:5:2}
  day_str=${date_str_start:8:2}
  if [[ "$3" == "Y" ]]; then
  	filename_suffix_builder="${year_str}"
  fi
  if [[ "$3" == "M" ]]; then
  	filename_suffix_builder="${year_str}"
  	filename_suffix_builder="${filename_suffix_builder}_${month_str}"
  fi
  if [[ "$3" == "D" ]]; then
  	filename_suffix_builder="${year_str}"
  	filename_suffix_builder="${filename_suffix_builder}_${month_str}"
  	filename_suffix_builder="${filename_suffix_builder}_${day_str}"
  fi
  #echo "filename_suffix_builder: ${filename_suffix_builder}"

  # Make the Current filename
  collection_name=$4 													# WV03_MSI_L1B___1_
  file_base_name="${collection_name}${filename_suffix_builder}"  		# WV03_MSI_L1B___1_2014
  out_filename="${file_base_name}.json"              					# WV03_MSI_L1B___1_2014.json
  output_subdir=$5  													# some/path
  out_full_file_path="${output_subdir}/${out_filename}" 				# some/path/WV03_MSI_L1B___2014.json
  json__name=$file_base_name


  # Now make new JSON from the incoming json.
  # # This breaks - for some reason it only reads the first line of the JSON file.
  incoming_template_json=$in_template_json  # GLOBALLY REFERENCED - When this is not globally referenced, it only reads the first line of JSON the '{' and that's all..

  # Make the new Date Time Variables
  start_date="${date_str_start}${time_suffix}"
  end_date="${date_str_end}${time_suffix}"

  new_json=$(echo "$incoming_template_json" | jq --arg name "$file_base_name" '. + { "name": $name }') 	# Create a new property called 'name'  # WV03_MSI_L1B___1_2099
  new_json=$(echo "$new_json" | jq --arg dts "$start_date" '.meta.startDate = $dts')  						      # Overwrite only a specific meta sub property without affecting other existing meta properties
  new_json=$(echo "$new_json" | jq --arg dte "$end_date" '.meta.endDate = $dte') 							          # Overwrite only a specific meta sub property without affecting other existing meta properties

  # Finally, write the final output file
  echo "$new_json" > "$out_full_file_path"
  echo "Just wrote file: ${out_full_file_path}"

}






# Create the list of Dates and then call a template file creation function for each of these

# initialize date variable to start_date
date=$date_start

# Check to see if this is running on a mac or not (slightly different date commands between mac and linux)
echo ""
# List to store the date objects
date_list=()
if [[ "$is_mac" == true ]]; then
  echo "About to calculate the date ranges using the Mac Version of the code"
	while [[ "$date" < "$date_end" ]]
	do
	  #echo "Processing ${date}"
	  date_list+=("$date")  # append date to list
	  next_date=$date
	  if [[ "$file_time_step_unit" == "D" ]]; then
	    next_date=$(date -j -f "%Y-%m-%d" -v +${file_time_step_interval}d ${date} +%Y-%m-%d)
	  elif [[ "$file_time_step_unit" == "M" ]]; then
	    next_date=$(date -j -f "%Y-%m-%d" -v +${file_time_step_interval}m ${date} +%Y-%m-%d)
	  elif [[ "$file_time_step_unit" == "Y" ]]; then
	    next_date=$(date -j -f "%Y-%m-%d" -v +${file_time_step_interval}y ${date} +%Y-%m-%d)
	  else
	    echo "Invalid time step specified"
	    exit 1
	  fi
	  make_output_file $date $next_date $file_time_step_unit $out_files_base_name $output_subdir $in_template_file_path
	  date=$next_date
	done
else
  echo "About to calculate the date ranges using the NON Mac Version of the code"
  while [[ "$date" < "$date_end" ]]
  do
    #echo $date
    date_list+=("$date")  # append date to list
    next_date=$date
    if [[ "$file_time_step_unit" == "D" ]]; then
      next_date=$(date -d "$date + $file_time_step_interval days" +%Y-%m-%d)
    elif [[ "$file_time_step_unit" == "M" ]]; then
      next_date=$(date -d "$date + $file_time_step_interval months" +%Y-%m-%d)
    elif [[ "$file_time_step_unit" == "Y" ]]; then
      next_date=$(date -d "$date + $file_time_step_interval years" +%Y-%m-%d)
    else
      echo "Invalid time step specified"
      exit 1
    fi
    make_output_file $date $next_date $file_time_step_unit $out_files_base_name $output_subdir $in_template_file_path
    date=$next_date
  done

fi

# # Print the entire list of dates in one line. - Uncomment this line to debug the date generation
#echo ""
#echo "Verifying the Date list: ${date_list[@]}"
