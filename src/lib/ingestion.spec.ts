import * as crypto from 'node:crypto';

import test from 'ava';
import * as RTE from 'fp-ts/lib/ReaderTaskEither';
import { pipe } from 'fp-ts/lib/function';

import { mockGetObject, mockPutObject } from './aws/s3.fixture';
import {
  addUmmgChecksumsHandlerRT,
  MissingCmrFile,
  readUmmgRTE,
  recordWorkflowFailureRT,
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
          granuleId: 'an-id',
          files: [{ name: 'data.tif' }, { name: 'cmr.json' }],
        },
      ],
    },
  };

  t.is(await requireCmrFilesHandler(event), event.input);
});

test('requireCmrFilesHandler should reject when a single granule does not include a CMR file', async (t) => {
  const event = { input: { granules: [{ granuleId: 'an-id', files: [] }] } };

  await t.throwsAsync(requireCmrFilesHandler(event), {
    instanceOf: MissingCmrFile,
    message: 'an-id',
  });
});

test('requireCmrFilesHandler should reject when multiple granules do not include a CMR file', async (t) => {
  const granulesMissingCmrFile = [
    { granuleId: 'id2', files: [{ name: 'data2.tif' }] },
    { granuleId: 'id3', files: [{ name: 'data3.tif' }] },
  ];
  const event = {
    input: {
      granules: [
        { granuleId: 'id1', files: [{ name: 'data1.tif' }, { name: 'cmr.json' }] },
        ...granulesMissingCmrFile,
      ],
    },
  };

  await t.throwsAsync(requireCmrFilesHandler(event), {
    instanceOf: MissingCmrFile,
    message: 'id2,id3',
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

//------------------------------------------------------------------------------
// recordWorkflowFailureRT
//------------------------------------------------------------------------------

test('recordWorkflowFailureRT should return failure details upon successful write to S3', async (t) => {
  const cause = {
    errorMessage: 'an-error-message',
    errorType: 'an-error-type',
    trace: ['a-stack-trace'],
  };
  const event = {
    cumulus_meta: {
      cumulus_version: '1.2.3',
      execution_name: crypto.randomBytes(16).toString('hex'),
      state_machine: 'a-state-machine',
      parentExecutionArn: 'DiscoverAndQueueGranules:parent-name',
      workflow_start_time: 1702939307992,
      system_bucket: 'my-bucket',
    },
    exception: {
      Cause: JSON.stringify(cause),
    },
    meta: {
      stack: 'a-stack',
      workflow_name: 'a-workflow',
      collection: {
        name: 'a-collection',
        version: '001',
      },
      provider: {
        host: 'a-host',
      },
    },
    payload: {
      granules: [
        {
          granuleId: 'an-id',
        },
      ],
    },
  };
  const expected = {
    stack: event.meta.stack,
    cumulus_version: event.cumulus_meta.cumulus_version,
    state_machine_arn: event.cumulus_meta.state_machine,
    state_machine_name: event.meta.workflow_name,
    execution_name: event.cumulus_meta.execution_name,
    start_time: event.cumulus_meta.workflow_start_time / 1000,
    parent_execution_arn: event.cumulus_meta.parentExecutionArn,
    collection_name: event.meta.collection.name,
    collection_version: event.meta.collection.version,
    provider_bucket: event.meta.provider.host,
    granule_ids: event.payload.granules.map(({ granuleId }) => granuleId),
    error_type: cause.errorType ?? 'UnknownError',
    error_message: cause.errorMessage ?? '',
    error_trace: cause.trace ?? [],
  };

  const program = recordWorkflowFailureRT(event);
  const actual = await program({ s3: { putObject: mockPutObject } })();

  const contents = await mockGetObject({
    Bucket: event.cumulus_meta.system_bucket,
    Key: [
      'failures',
      event.meta.workflow_name,
      'DiscoverAndQueueGranules-parent-name',
      `${event.cumulus_meta.execution_name}.json`,
    ].join('/'),
  }).then((output) => output.Body?.transformToString());

  t.is(contents, JSON.stringify(expected));
  t.deepEqual(actual, expected);
});

test('recordWorkflowFailureRT should parse CMR errors', async (t) => {
  const cause = {
    errorType: 'Error',
    errorMessage:
      'Failed to ingest, statusCode: 422,' +
      ' statusMessage: Unprocessable Entity,' +
      ' CMR error message: [{"path":["RelatedUrls"],"errors":["..."]}]',
    trace: ['a-stack-trace'],
  };
  const event = {
    cumulus_meta: {
      cumulus_version: '1.2.3',
      execution_name: crypto.randomBytes(16).toString('hex'),
      state_machine: 'a-state-machine',
      parentExecutionArn: 'DiscoverAndQueueGranules:parent-name',
      workflow_start_time: 1702939307992,
      system_bucket: 'my-bucket',
    },
    exception: {
      Cause: JSON.stringify(cause),
    },
    meta: {
      stack: 'a-stack',
      workflow_name: 'a-workflow',
      collection: {
        name: 'a-collection',
        version: '001',
      },
      provider: {
        host: 'a-host',
      },
    },
    payload: {
      granules: [
        {
          granuleId: 'an-id',
        },
      ],
    },
  };
  const expected = {
    stack: event.meta.stack,
    cumulus_version: event.cumulus_meta.cumulus_version,
    state_machine_arn: event.cumulus_meta.state_machine,
    state_machine_name: event.meta.workflow_name,
    execution_name: event.cumulus_meta.execution_name,
    start_time: event.cumulus_meta.workflow_start_time / 1000,
    parent_execution_arn: event.cumulus_meta.parentExecutionArn,
    collection_name: event.meta.collection.name,
    collection_version: event.meta.collection.version,
    provider_bucket: event.meta.provider.host,
    granule_ids: event.payload.granules.map(({ granuleId }) => granuleId),
    error_type: 'CMRUnprocessableEntity',
    error_message: cause.errorMessage,
    error_trace: cause.trace,
  };

  const program = recordWorkflowFailureRT(event);
  const actual = await program({ s3: { putObject: mockPutObject } })();

  const contents = await mockGetObject({
    Bucket: event.cumulus_meta.system_bucket,
    Key: [
      'failures',
      event.meta.workflow_name,
      'DiscoverAndQueueGranules-parent-name',
      `${event.cumulus_meta.execution_name}.json`,
    ].join('/'),
  }).then((output) => output.Body?.transformToString());

  t.is(contents, JSON.stringify(expected));
  t.deepEqual(actual, expected);
});

test('recordWorkflowFailureRT should return failure details upon failed write to S3', async (t) => {
  const cause = {
    errorMessage: 'an-error-message',
    errorType: 'an-error-type',
    trace: ['a-stack-trace'],
  };
  const event = {
    cumulus_meta: {
      cumulus_version: '1.2.3',
      execution_name: crypto.randomBytes(16).toString('hex'),
      state_machine: 'a-state-machine',
      parentExecutionArn: 'an-arn',
      workflow_start_time: 1702939307992,
      system_bucket: 'no-such-bucket',
    },
    exception: {
      Cause: JSON.stringify(cause),
    },
    meta: {
      stack: 'a-stack',
      workflow_name: 'a-workflow',
      collection: {
        name: 'a-collection',
        version: '001',
      },
      provider: {
        host: 'a-host',
      },
    },
    payload: {
      granules: [
        {
          granuleId: 'an-id',
        },
      ],
    },
  };
  const expected = {
    stack: event.meta.stack,
    cumulus_version: event.cumulus_meta.cumulus_version,
    state_machine_arn: event.cumulus_meta.state_machine,
    state_machine_name: event.meta.workflow_name,
    execution_name: event.cumulus_meta.execution_name,
    start_time: event.cumulus_meta.workflow_start_time / 1000,
    parent_execution_arn: event.cumulus_meta.parentExecutionArn,
    collection_name: event.meta.collection.name,
    collection_version: event.meta.collection.version,
    provider_bucket: event.meta.provider.host,
    granule_ids: event.payload.granules.map(({ granuleId }) => granuleId),
    error_type: cause.errorType ?? 'UnknownError',
    error_message: cause.errorMessage ?? '',
    error_trace: cause.trace ?? [],
  };

  const program = recordWorkflowFailureRT(event);
  const actual = await program({ s3: { putObject: mockPutObject } })();

  await t.throwsAsync(
    () =>
      mockGetObject({
        Bucket: event.cumulus_meta.system_bucket,
        Key: `failures/${event.meta.workflow_name}/${event.cumulus_meta.execution_name}.json`,
      }),
    { message: 'Bucket not found: no-such-bucket' }
  );

  t.deepEqual(actual, expected);
});
