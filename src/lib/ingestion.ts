import { s3 } from '@cumulus/aws-client/services';
import * as CMR from '@cumulus/cmrjs';
import * as E from 'fp-ts/lib/Either';
import * as J from 'fp-ts/lib/Json';
import * as O from 'fp-ts/lib/Option';
import * as P from 'fp-ts/lib/Predicate';
import * as RT from 'fp-ts/lib/ReaderTask';
import * as RTE from 'fp-ts/lib/ReaderTaskEither';
import * as RA from 'fp-ts/lib/ReadonlyArray';
import { constant, pipe } from 'fp-ts/lib/function';
import * as t from 'io-ts';

import * as L from './aws/lambda';
import * as S3 from './aws/s3';
import { safeDecodeTo } from './io';
import * as UMM from './umm';

export const PreSyncGranuleFile = t.readonly(
  t.type({
    name: t.string,
  })
);

export const PostSyncGranuleFile = t.intersection([
  t.readonly(
    t.type({
      bucket: t.string,
      key: t.string,
      fileName: t.string,
    })
  ),
  t.partial({
    checksumType: t.string,
    checksum: t.string,
  }),
]);

export const PreSyncGranule = t.readonly(
  t.type({
    granuleId: t.string,
    files: t.readonlyArray(PreSyncGranuleFile),
  })
);

export const PostSyncGranule = t.readonly(
  t.type({
    files: t.readonlyArray(PostSyncGranuleFile),
  })
);

export const PreSyncEvent = t.readonly(
  t.type({
    input: t.readonly(
      t.type({
        granules: t.readonlyArray(PreSyncGranule),
      })
    ),
  })
);

export const PostSyncEvent = t.readonly(
  t.type({
    input: t.readonly(
      t.type({
        granules: t.readonlyArray(PostSyncGranule),
      })
    ),
  })
);

export const FailedEvent = t.readonly(
  t.type({
    cumulus_meta: t.readonly(
      t.type({
        cumulus_version: t.string,
        execution_name: t.string,
        state_machine: t.string,
        parentExecutionArn: t.string,
        workflow_start_time: t.number,
        system_bucket: t.string,
      })
    ),
    exception: t.readonly(
      t.partial({
        Error: t.string,
        Cause: t.string, // Possible JSON object: { errorType, errorMessage, trace }
      })
    ),
    meta: t.readonly(
      t.type({
        stack: t.string,
        workflow_name: t.string,
        collection: t.readonly(
          t.type({
            name: t.string,
            version: t.string,
          })
        ),
        provider: t.readonly(
          t.type({
            host: t.string,
          })
        ),
      })
    ),
    payload: t.readonly(
      t.type({
        granules: t.readonlyArray(
          t.readonly(
            t.type({
              granuleId: t.string,
            })
          )
        ),
      })
    ),
  })
);

export type PreSyncGranuleFile = t.TypeOf<typeof PreSyncGranuleFile>;
export type PreSyncGranule = t.TypeOf<typeof PreSyncGranule>;
export type PreSyncEvent = t.TypeOf<typeof PreSyncEvent>;

export type PostSyncGranuleFile = t.TypeOf<typeof PostSyncGranuleFile>;
export type PostSyncGranule = t.TypeOf<typeof PostSyncGranule>;
export type PostSyncEvent = t.TypeOf<typeof PostSyncEvent>;

export type FailedEvent = t.TypeOf<typeof FailedEvent>;

// eslint-disable-next-line functional/no-class
export class MissingCmrFile extends Error {
  constructor(granuleId: string) {
    super(granuleId);
    // eslint-disable-next-line functional/no-this-expression
    this.name = this.constructor.name;
    // eslint-disable-next-line functional/no-this-expression
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 *
 * @param file
 * @returns
 */
export const readUmmgRTE = (file: PostSyncGranuleFile) =>
  pipe(
    S3.safeReadObject({ Bucket: file.bucket, Key: file.key }),
    RTE.chainEitherK(J.parse),
    RTE.mapLeft(E.toError),
    RTE.chainEitherK(safeDecodeTo(UMM.G))
  );

/**
 *
 * @param ummg
 * @returns
 */
export const addChecksumFrom =
  (ummgFile: PostSyncGranuleFile, ummg: UMM.G) => (file: PostSyncGranuleFile) =>
    CMR.isCMRFile(file)
      ? file // The target file is the CMR file itself, so do nothing
      : pipe(
          ummg.DataGranule.ArchiveAndDistributionInformation,
          RA.findFirst(({ Name }) => Name === file.fileName),
          O.filter(({ Checksum }) => Checksum !== undefined),
          O.map(({ Checksum }) => ({
            ...file,
            checksumType: Checksum?.Algorithm,
            checksum: Checksum?.Value,
          })),
          O.getOrElse(constant(file)),
          (file) => {
            const ummgFileStr = JSON.stringify(ummgFile);
            const ummgStr = JSON.stringify(ummg);
            const fileStr = JSON.stringify(file);

            file.checksum
              ? console.info(`Added checksum from ${ummgFileStr} to ${fileStr}`)
              : console.info(`Checksum not found for ${fileStr} in ${ummgStr}`);

            return file;
          }
        );

/**
 *
 * @param granule
 * @returns
 */
export const addChecksumsFromFileRT =
  (granule: PostSyncGranule) => (file: PostSyncGranuleFile) =>
    pipe(
      readUmmgRTE(file),
      RTE.match(
        // TODO make use of IO type?
        (e) => (console.error(e), granule),
        (ummg) => ({
          ...granule,
          files: granule.files.map(addChecksumFrom(file, ummg)),
        })
      )
    );

/**
 *
 * @param granule
 * @returns
 */
export const addUmmgChecksumsRT = (granule: PostSyncGranule) =>
  pipe(
    granule.files,
    RA.findFirst(CMR.isCMRFile),
    O.map(addChecksumsFromFileRT(granule)),
    O.getOrElse(
      () => (
        // TODO make use of IO type?
        console.warn(`Granule is missing a CMR file: ${JSON.stringify(granule)}`),
        RT.of(granule)
      )
    )
  );

/**
 * Decoded event handler for populating file checksums for all granules in the specified
 * event with the checksum information found within each granule's CMR JSON metadata
 * file in UMM-G format.
 *
 * @param event - ingestion event containing a possibly empty array of granules at the
 *    path `input.granules`
 * @returns a `ReaderTask<HasS3<'getObject'>, { ..., granules: Granule[] }>`
 * @function
 */
export const addUmmgChecksumsHandlerRT = (event: PostSyncEvent) =>
  pipe(
    event.input.granules,
    RT.traverseArray(addUmmgChecksumsRT),
    RT.map((granules) => ({ ...event.input, granules }))
  );

/**
 * Returns a Promise that resolves to the specified `event`, if every granule within the
 * `event.input.granules` array includes a CMR file in its `files` array; otherwise,
 * returns a Promise that rejects with an error indicating the granules that are missing
 * a CMR file.
 *
 * @param event - ingestion event containing a possibly empty array of granules at the
 *    path `input.granules`
 * @returns a Promise that resolves to the specified `event`, if every granule within
 *    the `event.input.granules` array includes a CMR file in its `files` array;
 *    otherwise, returns a Promise that rejects with an error indicating the granules
 *    that are missing a CMR file
 */
export const requireCmrFilesHandler = (event: PreSyncEvent) =>
  pipe(
    event.input.granules,
    RA.filter(({ files }) => pipe(files, RA.every(P.not(CMR.isCMRFile)))),
    E.fromPredicate(
      (granules) => granules.length === 0,
      (granules) => granules.map(({ granuleId }) => granuleId).join(',')
    ),
    E.match(
      (granuleId) => Promise.reject(new MissingCmrFile(granuleId)),
      () => Promise.resolve(event.input)
    )
  );

/**
 * Writes failure details to S3 for a failed workflow.
 *
 * The details are written as a JSON object on a single line so that it can be used as
 * data in an AWS Athena table for error reporting and analysis.
 *
 * The failure details are written to the system bucket specified by
 * `event.cumulus_meta.system_bucket` (typically the stack's "internal" bucket) at the
 * key `failures/${event.meta.workflow_name}/${event.cumulus_meta.execution_name}.json`
 * (e.g., `failures/IngestAndPublishGranules/467eb383-5336-4133-9f3d-6841174de6a4.json`).
 *
 * The JSON object contains the following properties:
 *
 * - `stack` - the name (prefix) of the Cumulus stack
 * - `cumulus_version` - the version of Cumulus
 * - `state_machine_arn` - the ARN of the state machine
 * - `state_machine_name` - the name of the step function that failed (e.g.,
 *   `IngestAndPublishGranule`)
 * - `execution_name` - the name (UUID) of the execution
 * - `start_time` - the start time of the workflow (in seconds since epoch)
 * - `parent_execution_arn` - the ARN of the parent execution of the workflow that failed
 * - `collection_name` - name of the collection that was being ingested
 * - `collection_version` - version of the collection that was being ingested
 * - `provider_bucket` - bucket of the provider
 * - `granule_ids` - IDs of the granules that were being ingested (controlled by the
 *   collection's `meta.preferredQueueBatchSize` property)
 * - `error_type` - the type of error that occurred (e.g., `AccessDenied`)
 * - `error_message` - the error message
 * - `error_trace` - the stack trace of the error (array of strings)
 *
 * @param event - event containing information about the failed workflow
 * @returns error details that were written to S3, even if the write failed (in which
 *   case the error details are written to CloudWatch Logs as a fallback)
 */
export const recordWorkflowFailureRT = (event: FailedEvent) => {
  const failureDetails = toFailureDetails(event);
  const bucket = event.cumulus_meta.system_bucket;
  const { parentExecutionArn } = event.cumulus_meta;
  const parentExecutionName = parentExecutionArn.split(':').slice(-1)[0];
  const key = [
    'failures',
    event.meta.workflow_name,
    `DiscoverAndQueueGranules-${parentExecutionName}`,
    `${event.cumulus_meta.execution_name}.json`,
  ].join('/');

  return pipe(
    S3.safePutObject({
      Bucket: bucket,
      Key: key,
      Body: JSON.stringify(failureDetails),
      ContentType: 'application/json',
    }),
    RTE.tap((output) => {
      console.info({ info: `Wrote failure details to s3://${bucket}/${key}` });
      return RTE.right(output);
    }),
    RTE.tapError((error) => {
      console.error({
        error: error.name,
        message: `Failed to write failure details to S3: ${error.message}`,
        bucket,
        key,
        failure: failureDetails,
      });
      return RTE.left(error);
    }),
    RTE.match(constant(failureDetails), constant(failureDetails))
  );
};

/**
 * Returns failure details suitable for writing to S3 for use with Athena for
 * error reporting and analysis.
 *
 * @param event - event containing information about the failed workflow
 * @returns failure details suitable for writing to S3 for use with Athena
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const toFailureDetails = (event: any) => {
  const { cumulus_meta = {}, meta = {}, payload = {}, exception = {} } = event;
  const cause = parseCause(exception);

  return {
    stack: meta.stack ?? 'Unknown',
    cumulus_version: cumulus_meta.cumulus_version ?? 'Unknown',
    state_machine_arn: cumulus_meta.state_machine ?? 'Unknown',
    state_machine_name: meta.workflow_name ?? 'Unknown',
    execution_name: cumulus_meta.execution_name ?? 'Unknown',
    start_time: (cumulus_meta.workflow_start_time ?? 0) / 1000,
    parent_execution_arn: cumulus_meta.parentExecutionArn ?? 'Unknown',
    collection_name: meta.collection?.name ?? 'Unknown',
    collection_version: meta.collection?.version ?? 'Unknown',
    provider_bucket: meta.provider?.host ?? 'Unknown',
    granule_ids: payload.granules?.map(({ granuleId = 'Unknown' }) => granuleId) ?? [],
    error_type: cause.errorType ?? 'Unknown',
    error_message: cause.errorMessage ?? JSON.stringify(event),
    error_trace: cause.trace ?? [],
  };
};

/**
 * Parses a JSON string representing an error cause and returns the parsed object.
 * If parsing fails, it tries to determine the error type based on the string and
 * returns an object with the error type and error message.
 *
 * @param causeJSON - JSON string representing the error cause
 * @returns parsed object or an object with the error type and error message
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const parseCause = ({ Error: error, Cause: causeJSON }: any) => {
  // The Cause property is always a string, but it may or may not be a JSON string.
  try {
    const cause = JSON.parse(causeJSON);

    // The Cause is a JSON string, so we can parse it and use the errorType property
    // as the error type when the Error property is undefined.  We also assume that
    // the parsed object contains an errorMessage property, and possibly a trace
    // property, which is an array of strings representing the stack trace.
    return {
      ...cause,
      errorType:
        !error || error === 'Error'
          ? parseErrorType(cause.errorMessage) ?? cause.errorType
          : error,
    };
  } catch {
    // The Cause did not parse as JSON, so we simply treat it as a plain string and
    // use it as the error message.
    return {
      errorType: !error || error === 'Error' ? parseErrorType(causeJSON) : error,
      errorMessage: causeJSON,
    };
  }
};

const parseErrorType = (cause: string): string | undefined => {
  // The Cumulus PostToCmr Lambda function reports CMR errors either as type 'Error'
  // or as type 'CMRInternalError'.  Since error type 'Error' isn't helpful, we look
  // at the cause to see if it is of the form '*statusMessage: <status>, CMR error*',
  // which is the structure of the error message PostToCmr throws when a CMR error
  // occurs.

  const matches = cause.match(
    /statusCode: (?<code>.+), statusMessage: (?<status>.+), CMR error/i
  );
  const code = matches?.groups?.code;
  const status = matches?.groups?.status.replace(' ', '').replace('-', '');

  if (code && !+code) {
    // The status code is non-numeric (e.g., 'ECONNRESET'), so return it as the
    // error type.  Numeric status codes will not be used as error types.
    return code;
  }

  if (status) {
    // We matched a specific status label (e.g., 'Unprocessable Entity'), so we'll use
    // it as the basis for a more helpful error type (e.g., 'CMRUnprocessableEntity')
    return `CMR${status}`;
  }

  if (cause.toLocaleLowerCase().includes('cmr error')) {
    // In case we couldn't extract a more specific error type, we can at least indicate
    // that there was some sort of CMR error.
    return 'CMRError';
  }

  // There are some cases where the Cumulus Message Adapter (CMA) causes a timeout,
  // but AWS does not properly report it as a timeout error.  In these cases, we can
  // determine that the error was a timeout by looking at the cause.
  return cause.toLowerCase().includes('timed out') ? 'TimeoutError' : undefined;
};

//------------------------------------------------------------------------------
// Lambda function handlers
//------------------------------------------------------------------------------

export const addUmmgChecksumsCMAHandler = pipe(
  (event: PostSyncEvent) => addUmmgChecksumsHandlerRT(event)({ s3: s3() })(),
  L.asyncHandlerFor(PostSyncEvent),
  L.cmaAsyncHandler
);

export const requireCmrFilesCMAHandler = pipe(
  requireCmrFilesHandler,
  L.asyncHandlerFor(PreSyncEvent),
  L.cmaAsyncHandler
);

export const recordWorkflowFailureHandler =
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async (event: any) => await recordWorkflowFailureRT(event)({ s3: s3() })();
