import { discoverGranules } from '@cumulus/discover-granules';
import * as dates from 'date-fns';
import * as O from 'fp-ts/Option';
import { constant, pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';
import * as fp from 'lodash/fp';

import * as cma from './cma';
import * as $t from './io';
import * as L from './lambda';
import { traceAsync } from './logging';

export const ProviderPathProps = t.readonly(
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

const CollectionMeta = t.readonly(
  t.type({ prefixGranuleIds: tt.fromNullable(t.boolean, false) })
);
type CollectionMeta = t.TypeOf<typeof CollectionMeta>;

const Collection = t.readonly(
  t.type({
    name: t.string,
    meta: tt.fromNullable(CollectionMeta, {} as CollectionMeta),
  })
);

export const DiscoverGranulesProps = t.readonly(
  t.type({
    config: t.type({
      collection: Collection,
    }),
  })
);

export const Granule = t.type({
  granuleId: t.string,
});

export const GranulesPayload = t.type({
  granules: t.readonlyArray(Granule),
});

export type ProviderPathProps = t.TypeOf<typeof ProviderPathProps>;
export type DiscoverGranulesProps = t.TypeOf<typeof DiscoverGranulesProps>;
export type Granule = t.TypeOf<typeof Granule>;
export type GranulesPayload = t.TypeOf<typeof GranulesPayload>;

type DiscoverGranules = (props: DiscoverGranulesProps) => Promise<GranulesPayload>;

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
 * @param props - granule discovery properties
 * @returns the provider path for granule discovery
 */
export const formatProviderPath = (props: ProviderPathProps) => {
  const { providerPathFormat, startDate } = props.config;
  return dates.format(startDate, providerPathFormat);
};

/**
 * Decorates the specified function, possibly applying the `prefixGranuleIds` function
 * to the output of the specified function.  The specified function must have the same
 * signature as the `discoverGranules` function from the `@cumulus/discover-granules`
 * module.
 *
 * Returns a function that also has the same signature as the `discoverGranules`
 * function.  However, upon invocation, the returned function invokes the specified
 * function, and then may or may not apply the `prefixGranuleIds` function to the
 * result before returning it.
 *
 * When the returned function is invoked, if the input event contains the value `true`
 * at the path `config.collection.meta.prefixGranuleIds`, it applies the function
 * `prefixGranuleIds` to the result of invoking the wrapped function, before returning
 * the final result.
 *
 * In the following examples, we define `mockDiscoverGranules` to mock the
 * `discoverGranules` function. The ability to easily mock `discoverGranules` is the
 * reason for defining the function as an input to be wrapped/decorated.
 *
 * In the first example, since `props1` does _not_ specify a
 * `config.collection.meta.prefixGranuleIds` property set to `true`, the granule IDs
 * produced by `mockDiscoverGranules` are _not_ prefixed with the name of the
 * collection.
 *
 * However, in the second example, we do set such a property to `true`. Thus, the
 * granule IDs _are_ prefixed with the name of the collection.
 *
 * @example
 * > const mockDiscoverGranules = async (props: DiscoverGranulesProps) => ({
 * ...   granules: [{ granuleId: '12345', ... }]
 * ... })
 * undefined
 * > const props1 = { config: { collection: { name: 'MyCollection' } } };
 * undefined
 * > await discoverGranulesPrefixingIds(mockDiscoverGranules)(props1);
 * { granules: [{ granuleId: '12345', ... }] }
 *
 * @example
 * > const props2 = { config: { collection: {
 * ...   name: 'MyCollection',
 * ...   prefixGranuleIds: true
 * ... }}};
 * undefined
 * > await discoverGranulesPrefixingIds(mockDiscoverGranules)(props2);
 * { granules: [{ granuleId: 'MyCollection-12345', ... }] }
 *
 * @param discover - function to be decorated, which must have the same signature as
 *    the `discoverGranules` function from the `@cumulus/discover-granules` module.
 * @returns function wrapping the specified function, which applies the
 *    `prefixGranuleIds` function to the output of the specified function if the input
 *    to the wrapping function contains a property at the path
 *    `config.collection.meta.prefixGranuleIds` set to `true`; otherwise, does nothing
 *    to the output (thus behaving identically to the wrapped function)
 */
export const discoverGranulesPrefixingIds =
  (discover: DiscoverGranules): DiscoverGranules =>
  (props: DiscoverGranulesProps): Promise<GranulesPayload> =>
    discover(props).then(
      props.config.collection.meta.prefixGranuleIds
        ? prefixGranuleIds(props.config.collection.name)
        : t.identity
    );

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
export const advanceStartDate = (props: ProviderPathProps): string | null => {
  const { startDate, step } = props.config;
  const now = () => new Date(Date.now());
  const endDate = pipe(props.config.endDate, O.getOrElse(now));
  const addDuration = (d: dates.Duration) => dates.add(startDate, d);
  const nextStartDate = pipe(step, O.match(constant(endDate), addDuration));

  return nextStartDate < endDate ? nextStartDate.toISOString() : null;
};

//------------------------------------------------------------------------------
// HANDLERS
//------------------------------------------------------------------------------

const mkProviderPathHandler = L.mkAsyncHandler(ProviderPathProps);

// For testing

export const formatProviderPathHandler = traceAsync(
  mkProviderPathHandler(formatProviderPath)
);
export const advanceStartDateHandler = traceAsync(
  mkProviderPathHandler(advanceStartDate)
);

// For Lambda functions

export const formatProviderPathCMAHandler = cma.asyncHandler(formatProviderPathHandler);
export const discoverGranulesCMAHandler = cma.asyncHandler(
  L.mkAsyncHandler(DiscoverGranulesProps)(
    discoverGranulesPrefixingIds(discoverGranules)
  )
);
export const advanceStartDateCMAHandler = cma.asyncHandler(advanceStartDateHandler);
