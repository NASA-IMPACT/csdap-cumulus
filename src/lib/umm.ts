import * as t from 'io-ts';
import * as tt from 'io-ts-types';

export const ChecksumAlgorithm = t.keyof({
  'Adler-32': null,
  'BSD checksum': null,
  'Fletcher-32': null,
  'Fletcher-64': null,
  'MD5': null,
  'POSIX': null,
  'SHA-1': null,
  'SHA-2': null,
  'SHA-256': null,
  'SHA-384': null,
  'SHA-512': null,
  'SM3': null,
  'SYSV': null,
});

export const Checksum = t.readonly(
  t.type({
    Value: t.string, // TODO refine to 1 <= len <= 128
    Algorithm: t.string,
  })
);

export const File = t.readonly(
  t.intersection([
    t.type({
      Name: t.string, // TODO refine to 1 <= len <= 1024
    }),
    t.partial({
      Checksum: Checksum,
    }),
  ])
);

export const ArchiveAndDistributionInformation = t.readonly(tt.nonEmptyArray(File));

export const DataGranule = t.readonly(
  t.type({
    ArchiveAndDistributionInformation: ArchiveAndDistributionInformation,
  })
);

export const G = t.readonly(
  t.type({
    DataGranule: DataGranule,
  })
);

export type ArchiveAndDistributionInformation = t.TypeOf<
  typeof ArchiveAndDistributionInformation
>;
export type Checksum = t.TypeOf<typeof Checksum>;
export type ChecksumAlgorithm = t.TypeOf<typeof ChecksumAlgorithm>;
export type DataGranule = t.TypeOf<typeof DataGranule>;
export type File = t.TypeOf<typeof File>;
export type G = t.TypeOf<typeof G>;
