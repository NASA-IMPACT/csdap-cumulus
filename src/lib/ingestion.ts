import { s3 } from '@cumulus/aws-client/services';
import * as CMR from '@cumulus/cmrjs';
import * as E from 'fp-ts/Either';
import * as J from 'fp-ts/Json';
import * as O from 'fp-ts/Option';
import * as RT from 'fp-ts/ReaderTask';
import * as RTE from 'fp-ts/ReaderTaskEither';
import * as RA from 'fp-ts/ReadonlyArray';
import { constant, pipe } from 'fp-ts/function';
import * as t from 'io-ts';

import * as L from './aws/lambda';
import * as S3 from './aws/s3';
import { safeDecodeTo } from './io';
import * as UMM from './umm';

export const GranuleFileID = t.readonly(
  t.type({
    bucket: t.string,
    key: t.string,
  })
);

export const GranuleFile = t.intersection([
  GranuleFileID,
  t.readonly(
    t.type({
      fileName: t.string,
    })
  ),
  t.readonly(
    t.partial({
      checksumType: t.string,
      checksum: t.string,
    })
  ),
]);

export const Granule = t.readonly(
  t.type({
    files: t.readonlyArray(GranuleFile),
  })
);

export const IngestEvent = t.readonly(
  t.type({
    input: t.readonly(
      t.type({
        granules: t.readonlyArray(Granule),
      })
    ),
  })
);

export type GranuleFileID = t.TypeOf<typeof GranuleFileID>;
export type GranuleFile = t.TypeOf<typeof GranuleFile>;
export type Granule = t.TypeOf<typeof Granule>;
export type IngestEvent = t.TypeOf<typeof IngestEvent>;

/**
 *
 * @param fileId
 * @returns
 */
export const readUmmgRTE = (fileId: GranuleFileID) =>
  pipe(
    S3.safeReadObject({ Bucket: fileId.bucket, Key: fileId.key }),
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
  (ummgFile: GranuleFile, ummg: UMM.G) => (file: GranuleFile) =>
    CMR.isCMRFile(file)
      ? file
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
export const addChecksumsFromFileRT = (granule: Granule) => (file: GranuleFile) =>
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
export const addUmmgChecksumsRT = (granule: Granule) =>
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
export const addUmmgChecksumsHandlerRT = (event: IngestEvent) =>
  pipe(
    event.input.granules,
    RT.traverseArray(addUmmgChecksumsRT),
    RT.map((granules) => ({ ...event.input, granules }))
  );

//------------------------------------------------------------------------------
// Lambda function handlers
//------------------------------------------------------------------------------

export const addUmmgChecksumsCMAHandler = pipe(
  (event: IngestEvent) => addUmmgChecksumsHandlerRT(event)({ s3: s3() })(),
  L.asyncHandlerFor(IngestEvent),
  L.cmaAsyncHandler
);
