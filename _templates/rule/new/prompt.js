// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'provider',
    message: "Provider ID:"
  },
  {
    type: 'input',
    name: 'collectionName',
    message: "Collection name:"
  },
  {
    type: 'input',
    name: 'collectionVersion',
    message: "Collection version:"
  },
  {
    type: 'input',
    name: 'providerPathFormat',
    message: "Provider path format (example: 'css/nga/WV03/1B/'yyyy/DDD):"
  },
  {
    type: 'input',
    name: 'year',
    message: "Year (YYYY):"
  }
]
