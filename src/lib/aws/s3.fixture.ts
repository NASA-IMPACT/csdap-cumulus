import { Readable } from 'stream';

import {
  GetObjectCommandInput,
  GetObjectCommandOutput,
  PutObjectCommandInput,
  PutObjectCommandOutput,
} from '@aws-sdk/client-s3';
import { sdkStreamMixin } from '@smithy/util-stream';

// eslint-disable-next-line functional/prefer-readonly-type
const store: { [Bucket: string]: { [Key: string]: string } } = {
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

export const mockGetObject = (
  args: GetObjectCommandInput
): Promise<GetObjectCommandOutput> => {
  const { Bucket, Key } = args;

  if (!Bucket) {
    return Promise.reject(new Error('No Bucket specified'));
  }
  if (!store[Bucket]) {
    return Promise.reject(new Error(`Bucket not found: ${Bucket}`));
  }
  if (!Key) {
    return Promise.reject(new Error('No Key specified'));
  }
  if (!store[Bucket][Key]) {
    return Promise.reject(new Error(`Object not found in bucket ${Bucket}: ${Key}`));
  }

  return Promise.resolve({
    $metadata: {},
    Body: sdkStreamMixin(Readable.from([store[Bucket][Key]])),
  });
};

export const mockPutObject = (
  args: PutObjectCommandInput
): Promise<PutObjectCommandOutput> => {
  const { Bucket, Key, Body } = args;

  if (!Bucket) {
    return Promise.reject(new Error('No Bucket specified'));
  }
  if (!Key) {
    return Promise.reject(new Error('No Key specified'));
  }
  if (!Body) {
    return Promise.reject(new Error('No Body specified'));
  }
  if (!store[Bucket]) {
    return Promise.reject(new Error(`Bucket not found: ${Bucket}`));
  }

  // eslint-disable-next-line functional/immutable-data
  store[Bucket][Key] = Body.toString();

  return Promise.resolve({ $metadata: {} });
};
