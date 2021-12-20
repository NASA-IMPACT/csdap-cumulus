import { Duration } from 'dayjs/plugin/duration';
import * as O from 'fp-ts/Option';
import { constant } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';

import * as CMA from './cma';
import dayjs from './dayjs';
import * as $t from './io';
import * as L from './lambda';
import { traceAsync } from './logging';

export const DiscoverGranulesProps = t.type({
  config: t.type({
    providerPathFormat: $t.DateFormat,
    startDate: tt.DateFromISOString,
    endDate: tt.optionFromNullable(tt.DateFromISOString),
    // TODO Restrict to positive durations
    step: tt.optionFromNullable($t.DurationFromISOString),
  }),
});

export type DiscoverGranulesProps = t.TypeOf<typeof DiscoverGranulesProps>;

/**
 * Returns the provider path for granule discovery.
 *
 * Uses the specified `providerPathFormat` property to format the `startDate` property
 * as the provider path.  Expects `providerPathFormat` to be a valid format according to
 * the [Day.js Format specification](https://day.js.org/docs/en/display/format).
 *
 * For example, if the `providerPathFormat` is `"[path/to/collection-name]-YYYY"`, and
 * the year of the `startDate` is 2019, returns the provider path as
 * `"path/to/collection-name-2019"`.
 *
 * @param props - granule discovery properties
 * @returns the provider path for granule discovery
 */
export const formatProviderPath = (props: DiscoverGranulesProps) => {
  const { providerPathFormat, startDate } = props.config;
  const providerPath = dayjs.utc(startDate).format(providerPathFormat);

  return providerPath;
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
 * @param props - granule discovery properties
 * @returns the next start date for granule discovery, or `null` if either the next
 *    start date is greater than or equal to the discovery end date or no step property
 *    is specified
 */
export const advanceStartDate = (props: DiscoverGranulesProps) => {
  const { startDate, step } = props.config;
  const endDate = O.getOrElse(() => new Date(Date.now()))(props.config.endDate);
  const addDuration = (d: Duration) => dayjs.utc(startDate).add(d).toDate();
  const nextStartDate = O.match(constant(endDate), addDuration)(step);

  return nextStartDate < endDate ? nextStartDate.toISOString() : null;
};

//------------------------------------------------------------------------------
// HANDLERS
//------------------------------------------------------------------------------

const mkDiscoverGranulesHandler = L.mkAsyncHandler(DiscoverGranulesProps);

// For testing

export const formatProviderPathHandler = traceAsync(
  mkDiscoverGranulesHandler(formatProviderPath)
);
export const advanceStartDateHandler = traceAsync(
  mkDiscoverGranulesHandler(advanceStartDate)
);

// For Lambda functions

export const formatProviderPathCMAHandler = CMA.asyncHandler(formatProviderPathHandler);
export const advanceStartDateCMAHandler = CMA.asyncHandler(advanceStartDateHandler);
