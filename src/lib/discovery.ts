import * as dates from 'date-fns';
import * as O from 'fp-ts/Option';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';
import * as fp from 'lodash/fp';

import * as L from './aws/lambda';
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
export const FormatProviderPathsOutput = t.intersection([
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

// Default maximum batch size for batching granules after discovery is 1000, but this
// can be set on a per rule basis by setting `meta.maxBatchSize` in a rule definition.
export const BatchGranulesInput = t.readonly(
  t.type({
    config: t.type({
      providerPath: t.string,
      maxBatchSize: tt.fromNullable(t.number, 1000),
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
export type FormatProviderPathsOutput = t.TypeOf<typeof FormatProviderPathsOutput>;
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
 * formatProviderPaths(
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
 * @param args.meta.startDate - the first date (UTC) to use for constructing provider
 *    paths
 * @param args.meta.endDate - optional, exclusive end date (UTC) for constructing
 *    provider paths (default: current date)
 * @param args.meta.step - optional ISO8601 duration between successive dates (default:
 *    entire time span between startDate and endDate)
 * @param args.meta.providerPathFormat - date format string used to construct a provider
 *    path from a date (must adhere to date-fns format specification)
 */
export const formatProviderPaths = (args: FormatProviderPathsInput) => {
  const { providerPathFormat, startDate, step } = args.meta;
  const now = () => new Date(Date.now());
  const endDate = pipe(args.meta.endDate, O.getOrElse(now));
  const dateFormatOptions = {
    useAdditionalDayOfYearTokens: true,
    useAdditionalWeekYearTokens: true,
  };
  const providerPaths = dateRange(startDate, endDate, step).map((date) =>
    dates.format(date, providerPathFormat, dateFormatOptions)
  );
  const encodedArgs = FormatProviderPathsInput.encode(args);

  console.info(
    JSON.stringify({
      startDate,
      endDate,
      step: O.getOrElseW(() => null)(step),
      numDates: providerPaths.length,
      providerPaths: A.ellipsize(providerPaths),
    })
  );

  return providerPaths.map((providerPath) =>
    fp.set('meta.providerPath', providerPath, encodedArgs)
  );
};

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
 * @param args.input - array of granule batches
 * @param args.config.batchIndex - index of the batch of granules to select
 * @returns element at the 0-based batch index in the input array
 */
export const unbatchGranules = (args: UnbatchGranulesInput): DiscoverGranulesOutput => {
  const { providerPath, batchIndex } = args.config;
  const batch = args.input[batchIndex];

  console.info(
    JSON.stringify({
      providerPath,
      numBatches: args.input.length,
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
  formatProviderPaths,
  L.asyncHandlerFor(FormatProviderPathsInput)
);

export const batchGranulesCMAHandler = pipe(
  batchGranules,
  L.asyncHandlerFor(BatchGranulesInput),
  L.cmaAsyncHandler
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
