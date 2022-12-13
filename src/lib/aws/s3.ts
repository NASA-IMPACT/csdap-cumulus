import { GetObjectCommandInput, GetObjectCommandOutput, S3 } from '@aws-sdk/client-s3';
import * as E from 'fp-ts/Either';
import * as RTE from 'fp-ts/ReaderTaskEither';
import * as TE from 'fp-ts/TaskEither';
import { pipe } from 'fp-ts/function';

export type HasS3<K extends keyof S3> = { readonly s3: Pick<S3, K> };

/**
 * Returns an S3 object using the `s3.getObject` function from the supplied reader.
 *
 * @param args - which S3 object to get
 * @returns response from getting the S3 object, with a `Body` property representing
 *    the contents of the object
 */
export const safeGetObject = (
  args: GetObjectCommandInput
): RTE.ReaderTaskEither<HasS3<'getObject'>, Error, GetObjectCommandOutput> =>
  TE.tryCatchK(({ s3 }) => s3.getObject(args), E.toError);

/**
 * Returns the contents of an S3 object, using the `s3.getObject` function from the
 * supplied reader to first get the object.
 *
 * @param args - which S3 object to read
 * @returns string contents of the specified S3 object
 */
export const safeReadObject = (
  args: GetObjectCommandInput
): RTE.ReaderTaskEither<HasS3<'getObject'>, Error, string> =>
  pipe(
    safeGetObject(args),
    RTE.chainTaskEitherK(
      TE.tryCatchK(
        (output) =>
          output.Body?.transformToString() ??
          Promise.reject(
            `Cannot stream output for ${JSON.stringify(args)}.` +
              `Output missing 'Body' property: ${JSON.stringify(output)}`
          ),
        E.toError
      )
    )
  );
