import test from 'ava';
import * as RT from 'fp-ts/ReaderTask';
import * as RTE from 'fp-ts/ReaderTaskEither';
import { pipe } from 'fp-ts/function';

import * as S3 from './s3';
import { getObject, getObjectNotFound } from './s3.fixture';

test('safeGetObject gets the contents of an existing object', async (t) => {
  const s3 = { getObject };
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
  const s3 = { getObject: getObjectNotFound };
  const program = pipe(
    S3.safeGetObject({ Bucket: 'my-bucket', Key: 'greeting.txt' }),
    RTE.matchE(
      (e) => RT.of(t.regex(e.message, /not found/)),
      (output) => RT.of(t.fail(`Unexpected output received: ${output}`))
    )
  );

  return program({ s3 })();
});
