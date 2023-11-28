import test from 'ava';
import * as RT from 'fp-ts/lib/ReaderTask';
import * as RTE from 'fp-ts/lib/ReaderTaskEither';
import { pipe } from 'fp-ts/lib/function';

import * as S3 from './s3';
import { mockGetObject, mockPutObject } from './s3.fixture';

test('safeGetObject gets the contents of an existing object', async (t) => {
  const s3 = { getObject: mockGetObject };
  const program = pipe(
    S3.safeGetObject({ Bucket: 'my-bucket', Key: 'greeting.txt' }),
    RTE.matchE(
      (e) => RT.of(t.fail(`Unexpected error: ${e}`)),
      (output) =>
        RT.fromTask(
          () =>
            output.Body?.transformToString().then((body) =>
              t.deepEqual(body, 'hello world!')
            ) ?? Promise.resolve(t.fail(`Output body undefined`))
        )
    )
  );

  return program({ s3 })();
});

test('safeGetObject returns Left(Error) upon S3 failure', async (t) => {
  const s3 = { getObject: mockGetObject };
  const program = pipe(
    S3.safeGetObject({ Bucket: 'no-such-bucket', Key: 'greeting.txt' }),
    RTE.matchE(
      (e) => RT.of(t.regex(e.message, /not found/)),
      (output) => RT.of(t.fail(`Unexpected output received: ${JSON.stringify(output)}`))
    )
  );

  return program({ s3 })();
});

test('safePutObject stores an object in an existing bucket', async (t) => {
  const s3 = { putObject: mockPutObject };
  const program = pipe(
    S3.safePutObject({ Bucket: 'my-bucket', Key: 'something-new', Body: 'foo' }),
    RTE.matchE(
      (e) => RT.of(t.fail(`Unexpected error: ${e}`)),
      (output) => RT.of(t.pass(JSON.stringify(output)))
    )
  );

  return program({ s3 })();
});

test('safePutObject returns Left(Error) upon S3 failure', async (t) => {
  const s3 = { putObject: mockPutObject };
  const program = pipe(
    S3.safePutObject({ Bucket: 'no-such-bucket', Key: 'something-new', Body: 'foo' }),
    RTE.matchE(
      (e) => RT.of(t.regex(e.message, /not found/)),
      (output) => RT.of(t.fail(`Unexpected output received: ${JSON.stringify(output)}`))
    )
  );

  return program({ s3 })();
});
