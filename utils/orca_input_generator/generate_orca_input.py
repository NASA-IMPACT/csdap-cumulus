import sys
import json
from pprint import pprint

# Resources:
# https://github.com/NASA-IMPACT/csdap-cumulus/issues/387
# https://github.com/NASA-IMPACT/csdap-cumulus/issues/279#issuecomment-1800344062

# Settings
SETTINGS__default_config_json = "config.json"

print(f'generate_orca_input.py: STARTED')

# JSON Loader
def load_json_to_dict(file_path):
    """
    Loads a JSON file at the given path into a Python dictionary.
    
    Args:
        file_path (str): The path to the JSON file. 
    
    Returns:
        dict: The loaded data as a dictionary.
    """
    with open(file_path, 'r') as f:
        data = json.load(f) 
    return data 



# Code to Actually Generate JSON Input for recovery Granules
def generate_orca_recovery_json__v1(config_dict={}):
    print(f'  generate_orca_recovery_json__v1: Started')
    ret_dict = {}

    ret_dict['payload'] = "TODO: Make an Object that goes here, it is a list of granules - May have to make this specific to the dataset or collection type"
    ret_dict['config'] = config_dict['config']

    print(f'  generate_orca_recovery_json__v1: Reached the End')
    return ret_dict



# Main Entry Point
def main():
    
    if len(sys.argv) > 1:
        input_config_json_file = sys.argv[1]
    else:
        input_config_json_file = SETTINGS__default_config_json

    print(f'')
    print(f'input_config_json_file: {input_config_json_file}')
    print(f'')
    #
    # Load the Config Dictionary
    print(f'Loading the Config Dictionary')
    config_dict = load_json_to_dict(input_config_json_file)
    print(f'config_dict: {config_dict}')
    print(f'')

    # Generate ORCA Recovery Input JSON from Config Dictonary
    print(f'Generating the ORCA Recovery JSON')
    orca_recoveery_json__v1 = generate_orca_recovery_json__v1(config_dict=config_dict)
    print(f'orca_recoveery_json__v1: (Next Lines)')
    pprint(orca_recoveery_json__v1)
    print(f'')



main()

# Example usage:
#data = load_json_to_dict("config.json") 
#print(data) 

print(f'generate_orca_input.py: Reached the End!')