// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
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
    name: 'sampleFilenamePrefix',
    message: "Sample filename prefix:"
  }
]
