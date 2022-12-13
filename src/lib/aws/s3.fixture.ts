import { Readable } from 'stream';

import { GetObjectCommandInput } from '@aws-sdk/client-s3';
import { sdkStreamMixin } from '@aws-sdk/util-stream-node';

const store: { readonly [Bucket: string]: { readonly [Key: string]: string } } = {
  'my-bucket': {
    'empty': '',
    'empty.json': '{}',
    'greeting.txt': 'hello world!',
    'cmr.json': JSON.stringify({
      DataGranule: {
        ArchiveAndDistributionInformation: [
          {
            Name: 'data-without-checksum.tif',
          },
          {
            Name: 'data-with-md5.tif',
            Checksum: {
              Algorithm: 'MD5',
              Value: '5',
            },
          },
          {
            Name: 'data-with-sha256.tif',
            Checksum: {
              Algorithm: 'SHA-256',
              Value: '256',
            },
          },
        ],
      },
    }),
  },
};

export const getObject = async (args: GetObjectCommandInput) => {
  const { Bucket, Key } = args;

  // eslint-disable-next-line functional/no-throw-statement
  if (!Bucket) throw new Error('No Bucket specified');
  // eslint-disable-next-line functional/no-throw-statement
  if (!store[Bucket]) throw new Error(`Bucket not found: ${Bucket}`);
  // eslint-disable-next-line functional/no-throw-statement
  if (!Key) throw new Error('No Key specified');
  if (!store[Bucket][Key])
    // eslint-disable-next-line functional/no-throw-statement
    throw new Error(`Object not found in bucket ${Bucket}: ${Key}`);

  return {
    $metadata: {},
    Body: sdkStreamMixin(Readable.from([store[Bucket][Key]])),
  };
};

export const getObjectNotFound = async () => Promise.reject(new Error('not found'));
