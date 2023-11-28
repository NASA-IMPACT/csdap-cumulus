import test from 'ava';
import * as RTE from 'fp-ts/lib/ReaderTaskEither';
import { pipe } from 'fp-ts/lib/function';

import { mockGetObject } from './aws/s3.fixture';
import {
  addUmmgChecksumsHandlerRT,
  readUmmgRTE,
  requireCmrFilesHandler,
} from './ingestion';

//------------------------------------------------------------------------------
// requireCmrFilesHandler
//------------------------------------------------------------------------------

test('requireCmrFilesHandler should resolve to original event when granules list is empty', async (t) => {
  const event = { input: { granules: [] } };

  t.is(await requireCmrFilesHandler(event), event.input);
});

test('requireCmrFilesHandler should resolve to original event when every granule includes a CMR file', async (t) => {
  const event = {
    input: {
      granules: [
        {
          files: [{ name: 'data.tif' }, { name: 'cmr.json' }],
        },
      ],
    },
  };

  t.is(await requireCmrFilesHandler(event), event.input);
});

test('requireCmrFilesHandler should reject when a single granule does not include a CMR file', async (t) => {
  const event = { input: { granules: [{ files: [] }] } };

  await t.throwsAsync(requireCmrFilesHandler(event), {
    message: (message) => message.endsWith(JSON.stringify(event.input.granules)),
  });
});

test('requireCmrFilesHandler should reject when multiple granules do not include a CMR file', async (t) => {
  const granulesMissingCmrFile = [
    { files: [{ name: 'data2.tif' }] },
    { files: [{ name: 'data3.tif' }] },
  ];
  const event = {
    input: {
      granules: [
        { files: [{ name: 'data1.tif' }, { name: 'cmr.json' }] },
        ...granulesMissingCmrFile,
      ],
    },
  };

  await t.throwsAsync(requireCmrFilesHandler(event), {
    message: (message) => message.endsWith(JSON.stringify(granulesMissingCmrFile)),
  });
});

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
  const actual = await program({ s3: { getObject: mockGetObject } })();

  t.deepEqual(actual, expected);
});

//------------------------------------------------------------------------------
// readUmmgRTE
//------------------------------------------------------------------------------

test(`readUmmgRTE should return Right(UMM.G) upon success`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'my-bucket', key: 'cmr.json', fileName: 'cmr.json' }),
    RTE.match(
      (e) => t.fail(String(e)),
      () => t.pass()
    )
  );

  return await program({ s3: { getObject: mockGetObject } })();
});

test(`readUmmgRTE should return Left(Error) for S3 failure`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'no-such-bucket', key: 'cmr.json', fileName: 'cmr.json' }),
    RTE.match(
      (e) => t.regex(e.message, /no-such-bucket/),
      () => t.fail('expected "no such bucket" error')
    )
  );

  return await program({ s3: { getObject: mockGetObject } })();
});

test(`readUmmgRTE should return Left(Error) for decoding failure`, async (t) => {
  const program = pipe(
    readUmmgRTE({ bucket: 'my-bucket', key: 'empty.json', fileName: 'empty.json' }),
    RTE.match(
      (e) => t.regex(e.message, /invalid value/i),
      () => t.fail('expected decoding error')
    )
  );

  return await program({ s3: { getObject: mockGetObject } })();
});
