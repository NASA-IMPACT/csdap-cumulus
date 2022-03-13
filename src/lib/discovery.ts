import { discoverGranules } from '@cumulus/discover-granules';
import { Duration } from 'dayjs/plugin/duration';
import * as O from 'fp-ts/Option';
import { constant, pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';
import * as fp from 'lodash/fp';

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
    step: tt.optionFromNullable($t.DurationFromISOString),
  }),
});

export const ConfigCollectionProps = t.readonly(
  t.type({
    config: t.readonly(t.type({ collection: t.readonly(t.type({ name: t.string })) })),
  })
);

export const Granule = t.type({
  granuleId: t.string,
});

export const GranulesPayload = t.type({
  granules: t.readonlyArray(Granule),
});

export type DiscoverGranulesProps = t.TypeOf<typeof DiscoverGranulesProps>;
export type ConfigCollectionProps = t.TypeOf<typeof ConfigCollectionProps>;
export type Granule = t.TypeOf<typeof Granule>;
export type GranulesPayload = t.TypeOf<typeof GranulesPayload>;

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
 * Returns a payload identical to the payload produced by the `discoverGranules` Lambda
 * Function, but where the `granuleId` of every granule has been prefixed with the
 * specified collection's name, delimited from the original `granuleId` by a dash (`-`).
 *
 * For example, if the collection's name given in the input config is `MyCollection`,
 * then each granule in the payload would have it's `granuleId` prefixed with
 * `MyCollection-`.  Thus, if on input, a granule's `granuleId` were `12345`, then on
 * output, it's `granuleId` would be `MyCollection-12345`.
 *
 * @example
 * const props = {
 *   config: {
 *     collection: {
 *       name: 'MyCollection'
 *     }
 *   }
 * };
 *
 * console.log(await discoverGranulesPrefixingIds(props));
 * // {
 * //   granules: [
 * //     {
 * //       granuleId: 'MyCollection-12345',
 * //       ...
 * //     },
 * //     ...
 * //   ]
 * // }
 *
 * @param props - granule ID prefix properties
 * @returns granules payload with collection name added as prefix to granule IDs
 */
export const discoverGranulesPrefixingIds = (
  props: ConfigCollectionProps
): Promise<GranulesPayload> =>
  discoverGranules(props).then(prefixGranuleIds(props.config.collection.name));

export const prefixGranuleIds = (collectionName: string) =>
  fp.tap<GranulesPayload>(
    fp.pipe(
      fp.prop('granules'),
      fp.forEach<Granule>(
        // We are modifying the granule objects in-place to avoid unnecessary memory
        // consumption, since the implementation of the `discoverGranules` function
        // already has memory issues, so we don't want to exacerbate the problem.
        // eslint-disable-next-line functional/immutable-data
        (granule) => (granule.granuleId = `${collectionName}-${granule.granuleId}`)
      )
    )
  );

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
export const advanceStartDate = (props: DiscoverGranulesProps): string | null => {
  const { startDate, step } = props.config;
  const now = () => new Date(Date.now());
  const endDate = pipe(props.config.endDate, O.getOrElse(now));
  const addDuration = (d: Duration) => dayjs.utc(startDate).add(d).toDate();
  const nextStartDate = pipe(step, O.match(constant(endDate), addDuration));

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
export const discoverGranulesCMAHandler = CMA.asyncHandler(
  L.mkAsyncHandler(ConfigCollectionProps)(discoverGranulesPrefixingIds)
);
export const advanceStartDateCMAHandler = CMA.asyncHandler(advanceStartDateHandler);
