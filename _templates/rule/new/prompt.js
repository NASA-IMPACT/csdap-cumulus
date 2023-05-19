// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'provider',
    message: "Provider ID (example: maxar):"
  },
  {
    type: 'input',
    name: 'collectionName',
    message: "Collection name (example: WV03_MSI_L1B):"
  },
  {
    type: 'input',
    name: 'collectionVersion',
    message: "Collection version (example: 1):"
  },
  {
    type: 'input',
    name: 'providerPathFormat',
    message: "Provider path format (example: 'css/nga/WV03/1B/'yyyy/DDD):"
  },
  {
    type: 'input',
    name: 'ingestedPathFormat',
    message: "Ingested path format (example: 'WV03_MSI_L1B___1/'yyyy/DDD):"
  },
  {
    type: 'input',
    name: 'year',
    message: "Year (YYYY):"
  }
]
