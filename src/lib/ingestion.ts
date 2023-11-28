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

export type PreSyncGranuleFile = t.TypeOf<typeof PreSyncGranuleFile>;
export type PreSyncGranule = t.TypeOf<typeof PreSyncGranule>;
export type PreSyncEvent = t.TypeOf<typeof PreSyncEvent>;

export type PostSyncGranuleFile = t.TypeOf<typeof PostSyncGranuleFile>;
export type PostSyncGranule = t.TypeOf<typeof PostSyncGranule>;
export type PostSyncEvent = t.TypeOf<typeof PostSyncEvent>;

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

const missingCmrFilesMessage = [
  'At least 1 granule in the input list is missing a file object representing a CMR',
  'metadata file. This indicates that either each such granule indeed has no such',
  "file amongst all of its files within the provider's bucket (in which case, you must",
  'populate them), or that the collection is misconfigured such that the CMR files are',
  "not identified during discovery (either because the 'granuleIdExtraction' regular",
  "expression is incorrect, or 'ignoreFilesConfigForDiscovery' is set to 'false' [or",
  "not specified] and the 'files' list does not include it or it is misconfigured)",
].join(' ');

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
      (granules) => `${missingCmrFilesMessage}: ${JSON.stringify(granules)}`
    ),
    E.match(
      (message) => Promise.reject(new Error(message)),
      () => Promise.resolve(event.input)
    )
  );

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
