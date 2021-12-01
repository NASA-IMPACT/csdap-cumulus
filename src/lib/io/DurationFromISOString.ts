import { Duration } from 'dayjs/plugin/duration';
import * as E from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as tt from 'io-ts-types';

import dayjs from '../dayjs';

export type DurationFromISOStringC = t.Type<Duration, string, unknown>;

/**
 * Codec to convert between strings and Duration objects.  When decoding a string,
 * it must be an [ISO 8601 Duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).
 *
 * @example
 * const d: Duration =
 *   E.getOrElse(() => dayjs.duration(0))(DurationFromISOString.decode('P1M'))
 *
 * @example
 * const MyType = t.type({
 *   d: DurationFromISOString,
 *   ...,
 * })
 */
export const DurationFromISOString: DurationFromISOStringC = new t.Type<
  Duration,
  string
>(
  'DurationFromISOString',
  (u): u is Duration => dayjs.isDuration(u) && !isNaN(u.asMilliseconds()),
  (u, c) =>
    pipe(
      tt.NonEmptyString.validate(u, c),
      E.map(dayjs.duration),
      E.chain((d) => (isNaN(d.asMilliseconds()) ? t.failure(u, c) : t.success(d)))
    ),
  (d: Duration) => d.toISOString()
);
