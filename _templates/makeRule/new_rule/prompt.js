// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'start_date_YYYY',
    message: "Start Year (Format: YYYY):"
  },
  {
    type: 'input',
    name: 'dataset_name',
    message: "Dataset Name (Example: WV04_MSI_L1B):"
  },
  {
    type: 'input',
    name: 'version_str',
    message: "Version Number (Example: 1):"
  },
  {
    type: 'input',
    name: 'provider_path_format',
    message: "providerPathFormat (Example: 'css/nga/WV03/1B/'yyyy/DDD):"
  }
]
