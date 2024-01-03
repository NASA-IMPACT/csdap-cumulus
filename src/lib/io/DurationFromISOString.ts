import * as dates from 'date-fns';
import * as duration from 'duration-fns';
import * as E from 'fp-ts/lib/Either';
import { pipe } from 'fp-ts/lib/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';

const DURATION_OBJECT_KEYS = Object.freeze([
  'years',
  'months',
  'weeks',
  'days',
  'hours',
  'minutes',
  'seconds',
  'milliseconds',
]);

export type DurationFromISOStringC = t.Type<dates.Duration, string, unknown>;

/**
 * Codec to convert between strings and Duration objects.  When decoding a string,
 * it must be an [ISO 8601 Duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).
 *
 * @example
 * import { Duration } from 'date-fns';
 *
 * const d: Duration =
 *   E.getOrElse(() => ({} as Duration))(DurationFromISOString.decode('P1M'))
 *
 * @example
 * const MyType = t.type({
 *   d: DurationFromISOString,
 *   ...,
 * })
 */
export const DurationFromISOString: DurationFromISOStringC = new t.Type<
  dates.Duration,
  string
>(
  'DurationFromISOString',
  (u): u is dates.Duration =>
    typeof u === 'object' &&
    u !== null &&
    Object.keys(u).every((k) => DURATION_OBJECT_KEYS.includes(k)),
  (u, c) =>
    pipe(
      tt.NonEmptyString.validate(u, c),
      E.chain(
        E.tryCatchK(
          duration.parse,
          (e) => [{ value: u, context: c, message: (e as Error).message }] as t.Errors
        )
      ),
      E.chain((d) => t.success(d))
    ),
  (d: dates.Duration) => duration.toString(d)
);
