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
  }
]