import { s3 } from '@cumulus/aws-client/services';
import * as dates from 'date-fns';
import * as O from 'fp-ts/lib/Option';
import { pipe } from 'fp-ts/lib/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';
import * as fp from 'lodash/fp';
import * as uuid from 'uuid';

import * as L from './aws/lambda';
import * as S3 from './aws/s3';
import * as $t from './io';
import * as A from './stdlib/arrays';
import { range as dateRange } from './stdlib/dates';

const Granule = t.type({
  granuleId: t.string,
});

const DiscoverGranulesOutput = t.readonly(
  t.type({
    granules: t.readonlyArray(Granule),
  })
);

export const FormatProviderPathsInput = t.readonly(
  t.type({
    cumulus_meta: t.readonly(
      t.type({
        system_bucket: t.string,
      })
    ),
    meta: t.readonly(
      t.type({
        providerPathFormat: $t.DateFormat,
        startDate: tt.DateFromISOString,
        endDate: tt.optionFromNullable(tt.DateFromISOString),
        step: tt.optionFromNullable($t.DurationFromISOString),
      })
    ),
  })
);

// Output is the same as the input, with the addition of `meta.providerPath`, so we
// simply construct an intersection of the two.
export const FormatProviderPathsItemOutput = t.intersection([
  FormatProviderPathsInput,
  t.readonly(
    t.type({
      meta: t.readonly(
        t.type({
          providerPath: t.string,
        })
      ),
    })
  ),
]);

type BucketKey = {
  readonly bucket: string;
  readonly key: string;
};

// Default maximum batch size for batching granules after discovery is 5000, but this
// can be set on a per rule basis by setting `meta.maxBatchSize` in a rule definition.
export const BatchGranulesInput = t.readonly(
  t.type({
    config: t.type({
      providerPath: t.string,
      maxBatchSize: tt.fromNullable(t.number, 5000),
    }),
    input: DiscoverGranulesOutput,
  })
);

export const UnbatchGranulesInput = t.readonly(
  t.type({
    config: t.type({
      providerPath: t.string,
      batchIndex: t.Int,
    }),
    input: t.readonlyArray(DiscoverGranulesOutput),
  })
);

const Collection = t.readonly(
  t.type({
    name: t.string,
    meta: tt.fromNullable(
      t.type({
        prefixGranuleIds: tt.fromNullable(t.boolean, false),
      }),
      {
        prefixGranuleIds: false,
      }
    ),
  })
);

export const PrefixGranuleIdsInput = t.readonly(
  t.type({
    config: t.type({
      collection: Collection,
    }),
    input: DiscoverGranulesOutput,
  })
);

type Granule = t.TypeOf<typeof Granule>;
type DiscoverGranulesOutput = t.TypeOf<typeof DiscoverGranulesOutput>;

export type FormatProviderPathsInput = t.TypeOf<typeof FormatProviderPathsInput>;
export type FormatProviderPathsItemOutput = t.TypeOf<
  typeof FormatProviderPathsItemOutput
>;
export type BatchGranulesInput = t.TypeOf<typeof BatchGranulesInput>;
export type UnbatchGranulesInput = t.TypeOf<typeof UnbatchGranulesInput>;
export type PrefixGranuleIdsInput = t.TypeOf<typeof PrefixGranuleIdsInput>;

/**
 * Returns an array (possibly empty) containing the input duplicated once per date step
 * from the start date, up to, but excluding the end date, along with the addition of
 * a provider path constructed from each date.
 *
 * More specifically, each element of the output array has a unique value inserted at
 * `meta.providerPath`.  Each such inserted value is constructed from a date in the date
 * range starting at the start date, one date step at a time, up to (but excluding) the
 * end date, using the value of `providerPathFormat` as the format pattern.
 *
 * Expects `providerPathFormat` to be a valid format according to the
 * [Unicode Date Format Patterns](
 * https://www.unicode.org/reports/tr35/tr35-dates.html#8-date-format-patterns).
 *
 * For example, if the `providerPathFormat` is `"'path/to/collection-name'-yyyy"`,
 * and the year of the `startDate` is 2019, sets the provider path as
 * `"path/to/collection-name-2019"`.  Note that any text within the date format pattern
 * that is surrounded by single quotes is taken literally, and the single quotes are
 * not present in the result.  This is according to the [date-fns format specification](
 * https://date-fns.org/docs/format), with the [date-fns format options](
 * https://date-fns.org/docs/format#arguments) `useAdditionalDayOfYearTokens` and
 * `useAdditionalWeekYearTokens` both set to `true`.
 *
 * This output is designed to serve as input to a StepFunction task of type "Map" where
 * the first step of the Map task is the DiscoverGranules Lambda function.  In other
 * words, every element of the output array is an input that DiscoverGranules expects,
 * each with a distinct `providerPath` covering a different timespan (e.g., daily,
 * monthly, or yearly from the start date to the end date).
 *
 * @example
 * generateDiscoverGranulesInputs(
 *   {
 *     ...,
 *     meta: {
 *       startDate: new Date('2020-01-01T00:00:00Z'),
 *       endDate: O.some(new Date('2020-03-01T00:00:00Z')),
 *       step: O.some({ days: 1 }),
 *       providerPathFormat: "'planet/PSScene3Band/'yyyyMMdd",
 *       ...,
 *     }
 *   }
 * )
 *
 * // Returns the following.  Note that the ellipses (...) represent properties of the
 * // input, all of which are passed through unchanged.  This function simply duplicates
 * // the original input for each date step, inserting a value for `meta.providerPath`
 * // for each:
 * //
 * // [
 * //   {
 * //     ...,
 * //     meta: {
 * //       providerPath: 'planet/PSScene3Band/20200101',
 * //       ...
 * //     }
 * //   },
 * //   {
 * //     ...,
 * //     meta: {
 * //       providerPath: 'planet/PSScene3Band/20200102',
 * //       ...
 * //     }
 * //   }
 * // ]
 *
 * @param event.meta.startDate - the first date (UTC) to use for constructing provider
 *    paths
 * @param event.meta.endDate - optional, exclusive end date (UTC) for constructing
 *    provider paths (default: current date)
 * @param event.meta.step - optional ISO8601 duration between successive dates (default:
 *    entire time span between startDate and endDate)
 * @param event.meta.providerPathFormat - date format string used to construct a
 *    provider path from a date (must adhere to date-fns format specification)
 */
export const generateDiscoverGranulesInputs = (event: FormatProviderPathsInput) => {
  const { providerPathFormat, startDate, endDate, step } = event.meta;
  const discoveryDates = discoveryDateRange(startDate, endDate, step);
  const providerPaths = discoveryDates.map(formatDateWith(providerPathFormat));

  console.info(
    JSON.stringify({
      startDate,
      endDate: O.getOrElseW(() => null)(endDate),
      step: O.getOrElseW(() => null)(step),
      numDates: providerPaths.length,
      providerPaths: A.ellipsize(providerPaths),
    })
  );

  return providerPaths
    .map(injectProviderPath(event))
    .map(FormatProviderPathsItemOutput.encode);
};

/**
 * Writes to S3 an array of inputs to DiscoverGranules.  The file is suitable to
 * use as input to a Distributed Map state in an AWS Step Function, which would
 * be configured with an `ItemReader` like so:
 *
 * ```plain
 * "ItemReader": {
 *   "Resource": "arn:aws:states:::s3:getObject",
 *   "ReaderConfig": {
 *       "InputType": "JSON"
 *   },
 *   "Parameters": {
 *       "Bucket.$": "$.bucket",
 *       "Key.$": "$.key"
 *   }
 * }
 * ```
 *
 * @param event.meta.startDate - the first date (UTC) to use for constructing provider
 *    paths
 * @param event.meta.endDate - optional, exclusive end date (UTC) for constructing
 *    provider paths (default: current date)
 * @param event.meta.step - optional ISO8601 duration between successive dates (default:
 *    entire time span between startDate and endDate)
 * @param event.meta.providerPathFormat - date format string used to construct a
 *    provider path from a date (must adhere to date-fns format specification)
 * @param event.meta.buckets.internal.name - name of the bucket to write to
 * @returns the bucket and key of the written S3 object containing the inputs
 */
export const writeDiscoverGranulesInputs =
  (event: FormatProviderPathsInput) =>
  async ({ s3 }: S3.HasS3<'putObject'>): Promise<BucketKey> => {
    const bucket = event.cumulus_meta.system_bucket;
    const key = `states/${uuid.v4()}.json`;

    await s3.putObject({
      Bucket: bucket,
      Key: key,
      Body: JSON.stringify(generateDiscoverGranulesInputs(event)),
      Expires: dates.addDays(Date.now(), 90),
      ContentType: 'application/json',
    });

    return { bucket, key };
  };

/**
 * Returns an array of sequential dates (possibly empty).
 *
 * @param startDate - starting date in the array
 * @param endDate - ending date (exclusive) (default: today)
 * @param step - duration between successive dates in the array (default:
 *    endDate - startDate)
 * @returns an array of sequential dates, starting with the start date, at a
 *    distance of `step` in between, ending with (but excluding) the end date;
 *    an empty array, if the start date is on or after the end date
 */
export const discoveryDateRange = (
  startDate: Date,
  endDate: O.Option<Date>,
  step: O.Option<dates.Duration>
): readonly Date[] => {
  const now = () => new Date(Date.now());
  return dateRange(startDate, pipe(endDate, O.getOrElse(now)), step);
};

/**
 * Returns a function that take a `Date` and formats it according to the given
 * date format.
 *
 * @param dateFormat - format used by the returned function for formatting dates
 * @returns a function that take a `Date` and formats it according to the given
 *    date format
 */
export const formatDateWith = (dateFormat: string): ((date: Date) => string) => {
  const dateFormatOptions = {
    useAdditionalDayOfYearTokens: true,
    useAdditionalWeekYearTokens: true,
  };

  return (date: Date) => dates.format(date, dateFormat, dateFormatOptions);
};

/**
 * Returns a copy of an event with a provider path string injected at the path
 * `meta.providerPath`.
 *
 * @param event - event in which to inject the provider path
 * @param providerPath - provider path to inject
 * @returns copy of event with provider path injected at `meta.providerPath`
 */
export const injectProviderPath =
  (event: FormatProviderPathsInput) =>
  (providerPath: string): FormatProviderPathsItemOutput => ({
    ...event,
    meta: {
      ...event.meta,
      providerPath,
    },
  });

/**
 * Splits a list of granules into batches of a maximum size.  Returns an array where
 * each element has the same structure as the input granules, but split into
 * batches.
 *
 * @example
 * batchGranules(
 *   {
 *     input: {
 *       granules: [
 *         { granuleId: 'a' },
 *         { granuleId: 'b' },
 *         { granuleId: 'c' },
 *         { granuleId: 'd' },
 *         { granuleId: 'e' },
 *       ],
 *     },
 *     config: {
 *       maxBatchSize: 2,
 *     }
 *   }
 * )
 *
 * // Output:
 * //
 * // [
 * //   {
 * //     granules: [
 * //       { granuleId: 'a' },
 * //       { granuleId: 'b' },
 * //     ]
 * //   },
 * //   {
 * //     granules: [
 * //       { granuleId: 'c' },
 * //       { granuleId: 'd' },
 * //     ]
 * //   },
 * //   {
 * //     granules: [
 * //       { granuleId: 'e' },
 * //     ]
 * //   },
 * // ]
 *
 * @param event.input.granules - full list of granules to split into batches
 * @param event.config.maxBatchSize - maximum batch size for batching granules listed
 *    by DiscoverGranules (default: 1000)
 * @returns an array of nearly equal-sized batches (arrays) of granules of the input
 *    granules array
 */
export const batchGranules = (
  event: BatchGranulesInput
): readonly DiscoverGranulesOutput[] => {
  const { input, config } = event;
  const { granules } = input;
  const { providerPath, maxBatchSize } = config;
  const batches = A.batches(granules, maxBatchSize).map((granules) => ({ granules }));

  console.info(
    JSON.stringify({
      providerPath,
      numGranules: granules.length,
      maxBatchSize,
      numBatches: batches.length,
      batchSizes: batches.map((batch) => batch.granules.length),
    })
  );

  return batches;
};

/**
 * Selects a single batch of granules from an array of batches.
 *
 * @param event.input - array of granule batches
 * @param event.config.batchIndex - index of the batch of granules to select
 * @returns element at the 0-based batch index in the input array
 */
export const unbatchGranules = (
  event: UnbatchGranulesInput
): DiscoverGranulesOutput => {
  const { providerPath, batchIndex } = event.config;
  const batch = event.input[batchIndex];

  console.info(
    JSON.stringify({
      providerPath,
      numBatches: event.input.length,
      batchIndex,
      batchSize: batch.granules.length,
    })
  );

  return batch;
};

/**
 * Prefixes the granule ID of each granule in an array of granules with the name of
 * their collection.  This is for cases where the granule IDs extracted from the names
 * of granule files do not include such a prefix, but the `GranuleUR` values within each
 * granule's UMM-G JSON file do.  This is necessary because the Cumulus pipeline will
 * fail to work properly when a granule's `granuleId` property does not match the
 * `GranuleUR` property within its CMM-R JSON file.
 *
 * NOTE: In order to cause this prefixing behavior to come into play during discovery
 * of granules for a particular collection, the collection definition must include a
 * `meta.prefixGranuleIds` property set to `true`.  In the absence of this property
 * setting in the collection definition, it defaults to `false`.
 *
 * @example
 * prefixGranuleIds(
 *   {
 *     config: {
 *       collection: { name: 'foo', ... },
 *     },
 *     input: {
 *       granules: [
 *         { granuleId: 'a', ... },
 *         { granuleId: 'b', ... },
 *         ...,
 *       ]
 *     }
 *   }
 * )
 *
 * // Output:
 * //
 * // {
 * //   granules: [
 * //     { granuleId: 'foo-a', ... },
 * //     { granuleId: 'foo-b', ... },
 * //   ]
 * // }
 *
 * @param args.config.collection - collection object with a `name` property for
 *    prefixing each granule ID
 * @param args.input.granules - array of granules whose `granuleId` properties will be
 *    prefixed with the collection name, separated by a dash (`-`)
 * @returns copy of `args.input`, but with the `granuleId` of each granule prefixed
 *    with the name of the collection, separated by a dash (`-`)
 */
export const prefixGranuleIds = (args: PrefixGranuleIdsInput) => {
  const { collection } = args.config;
  const { granules } = args.input;
  const prefix = `${collection.name}-`;

  console.info(`Prefixing granuleIds for ${granules.length} granules with '${prefix}'`);

  return {
    granules: granules.map((granule: Granule) =>
      fp.set('granuleId', `${prefix}${granule.granuleId}`, granule)
    ),
  };
};

//------------------------------------------------------------------------------
// Lambda function handlers
//------------------------------------------------------------------------------

export const formatProviderPathsHandler = pipe(
  (event: FormatProviderPathsInput) => writeDiscoverGranulesInputs(event)({ s3: s3() }),
  L.asyncHandlerFor(FormatProviderPathsInput)
);

export const batchGranulesCMAHandler = pipe(
  batchGranules,
  L.asyncHandlerFor(BatchGranulesInput),
  L.cmaAsyncHandlerIndexed('batchIndex')
);

export const unbatchGranulesCMAHandler = pipe(
  unbatchGranules,
  L.asyncHandlerFor(UnbatchGranulesInput),
  L.cmaAsyncHandler
);

export const prefixGranuleIdsCMAHandler = pipe(
  prefixGranuleIds,
  L.asyncHandlerFor(PrefixGranuleIdsInput),
  L.cmaAsyncHandler
);
