import * as dates from 'date-fns';
import * as tz from 'date-fns-tz';
import * as O from 'fp-ts/Option';
import { constant, pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';

import * as L from './aws/lambda';
import * as $t from './io';
import { traceAsync } from './logging';

const Granule = t.readonly(
  t.type({
    granuleId: t.string,
  })
);
const GranulesPayload = t.readonly(
  t.type({
    granules: t.array(Granule),
  })
);

type Granule = t.TypeOf<typeof Granule>;
type GranulesPayload = t.TypeOf<typeof GranulesPayload>;

export const ProviderPathInput = t.readonly(
  t.type({
    config: t.readonly(
      t.type({
        providerPathFormat: $t.DateFormat,
        startDate: tt.DateFromISOString,
        endDate: tt.optionFromNullable(tt.DateFromISOString),
        step: tt.optionFromNullable($t.DurationFromISOString),
      })
    ),
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
    input: GranulesPayload,
  })
);

export type PrefixGranuleIdsInput = t.TypeOf<typeof PrefixGranuleIdsInput>;
export type ProviderPathInput = t.TypeOf<typeof ProviderPathInput>;

/**
 * Returns the provider path for granule discovery.
 *
 * Uses the specified `providerPathFormat` property to format the `startDate` property
 * as the provider path.  Expects `providerPathFormat` to be a valid format according to
 * the [Unicode Date Format Patterns](
 * https://www.unicode.org/reports/tr35/tr35-dates.html#8-date-format-patterns).
 *
 * For example, if the `providerPathFormat` is `"'path/to/collection-name'-yyyy"`, and
 * the year of the `startDate` is 2019, returns the provider path as
 * `"path/to/collection-name-2019"`.  Note that any text within the date format pattern
 * that is surrounded by single quotes is taken literally, and the single quotes are
 * not present in the result.
 *
 * @param args - provider path keyword arguments
 * @returns the provider path for granule discovery
 */
export const formatProviderPath = (args: ProviderPathInput): string => {
  const { providerPathFormat, startDate } = args.config;
  return tz.formatInTimeZone(startDate, 'Z', providerPathFormat);
};

/**
 * Returns the specified `startDate` property advanced by the specified `step` duration.
 * Returns `null` if either no `step` is specified or the next start date is greater
 * than or equal to the `endDate`.
 *
 * The `endDate` is _exclusive_, and defaults to the current date/time.  When `step` is
 * specified, it is expected to be a valid
 * [ISO 8601 Duration](https://en.wikipedia.org/wiki/ISO_8601#Durations) string (for
 * example, `"P1M"` to represent 1 month).
 *
 * @param args - provider path keyword arguments
 * @returns the next start date for granule discovery, or `null` if either the next
 *    start date is greater than or equal to the discovery end date or no step property
 *    is specified
 */
export const advanceStartDate = (args: ProviderPathInput): string | null => {
  const { startDate, step } = args.config;
  const now = () => new Date(Date.now());
  const endDate = pipe(args.config.endDate, O.getOrElse(now));
  const addDuration = (d: dates.Duration) => dates.add(startDate, d);
  const nextStartDate = pipe(step, O.match(constant(endDate), addDuration));

  return nextStartDate < endDate ? nextStartDate.toISOString() : null;
};

/**
 *
 * @param args
 * @returns
 */
export const prefixGranuleIds = (args: PrefixGranuleIdsInput) => {
  const { collection } = args.config;
  const { granules } = args.input;
  const prefix = `${collection.name}-`;

  console.info(`Prefixing granuleIds for ${granules.length} granules with '${prefix}'`);

  return {
    granules: granules.map((granule: Granule) => ({
      ...granule,
      granuleId: `${prefix}${granule.granuleId}`,
    })),
  };
};

//------------------------------------------------------------------------------
// Lambda function handlers
//------------------------------------------------------------------------------

export const formatProviderPathCMAHandler = pipe(
  formatProviderPath,
  L.asyncHandlerFor(ProviderPathInput),
  traceAsync,
  L.cmaAsyncHandler
);

export const advanceStartDateCMAHandler = pipe(
  advanceStartDate,
  L.asyncHandlerFor(ProviderPathInput),
  traceAsync,
  L.cmaAsyncHandler
);

export const prefixGranuleIdsCMAHandler = pipe(
  prefixGranuleIds,
  L.asyncHandlerFor(PrefixGranuleIdsInput),
  L.cmaAsyncHandler
);
