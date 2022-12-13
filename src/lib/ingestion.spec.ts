import test from 'ava';
import * as RTE from 'fp-ts/ReaderTaskEither';
import { pipe } from 'fp-ts/function';

import { getObject } from './aws/s3.fixture';
import { addUmmgChecksumsHandlerRT, readUmmgRTE } from './ingestion';

//------------------------------------------------------------------------------
// addUmmgChecksumsHandlerRT
//------------------------------------------------------------------------------

test('addUmmgChecksumsHandlerRT should add checksums from cmr.json', async (t) => {
  const event = {
    input: {
      granules: [
        {
          granuleId: 'an-id',
          files: [
            { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
            { bucket: 'my-bucket', key: 'foo', fileName: 'data-without-checksum.tif' },
          ],
        },
        {
          granuleId: 'an-id',
          files: [
            { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
            { bucket: 'my-bucket', key: 'foo', fileName: 'data-with-md5.tif' },
          ],
        },
        {
          granuleId: 'an-id',
          files: [
            { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
            { bucket: 'my-bucket', key: 'foo', fileName: 'data-with-sha256.tif' },
          ],
        },
      ],
    },
  };

  const expected = {
    granules: [
      {
        granuleId: 'an-id',
        files: [
          { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
          { bucket: 'my-bucket', key: 'foo', fileName: 'data-without-checksum.tif' },
        ],
      },
      {
        granuleId: 'an-id',
        files: [
          { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
          {
            bucket: 'my-bucket',
            key: 'foo',
            fileName: 'data-with-md5.tif',
            checksumType: 'MD5',
            checksum: '5',
          },
        ],
      },
      {
        granuleId: 'an-id',
        files: [
          { bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' },
          {
            bucket: 'my-bucket',
            key: 'foo',
            fileName: 'data-with-sha256.tif',
            checksumType: 'SHA-256',
            checksum: '256',
          },
        ],
      },
    ],
  };

  const program = addUmmgChecksumsHandlerRT(event);
  const actual = await program({ s3: { getObject } })();

  t.deepEqual(actual, expected);
});

//------------------------------------------------------------------------------
// readUmmgRTE
//------------------------------------------------------------------------------

test(`readUmmgRTE should return Right(UMM.G) upon success`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'my-bucket', key: 'cmr.json' }),
    RTE.match(
      (e) => t.fail(String(e)),
      () => t.pass()
    )
  );

  return await program({ s3: { getObject } })();
});

test(`readUmmgRTE should return Left(Error) for S3 failure`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'no-such-bucket', key: 'cmr.json' }),
    RTE.match(
      (e) => t.regex(e.message, /no-such-bucket/),
      () => t.fail('expected "no such bucket" error')
    )
  );

  return await program({ s3: { getObject } })();
});

test(`readUmmgRTE should return Left(Error) for decoding failure`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'my-bucket', key: 'empty.json' }),
    RTE.match(
      (e) => t.regex(e.message, /invalid value/i),
      () => t.fail('expected decoding error')
    )
  );

  return await program({ s3: { getObject } })();
});
