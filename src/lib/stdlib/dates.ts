import * as dates from 'date-fns';
import * as O from 'fp-ts/lib/Option';
import * as RA from 'fp-ts/lib/ReadonlyArray';
import { constant, flow, pipe } from 'fp-ts/lib/function';

/**
 * Returns an array (possibly empty) of dates, starting with the `start` date, and
 * ending with (but excluding) the `end` date, with `step` duration between successive
 * dates.
 *
 * If `step` is `O.none`, it defaults to a duration spanning from `start` to `end`,
 * resulting in a single step from `start` to `end`.  If `start` is the same as, or
 * after, `end`, the range is empty.
 *
 * @example
 * range(new Date('2020-01-01'), new Date('2020-01-01'), O.some({ months: 1 }))
 * //=> []
 *
 * @example
 * range(new Date('2020-01-01'), new Date('2020-02-01'), O.some({ months: 1 }))
 * //=> [ 2020-01-01T00:00:00.000Z ]
 *
 * @example
 * range(new Date('2020-01-01'), new Date('2020-03-01'), O.some({ months: 1 }))
 * //=> [ 2020-01-01T00:00:00.000Z, 2020-02-01T00:00:00.000Z ]
 *
 * @example
 * range(new Date('2020-01-01'), new Date('2020-03-01'), O.none)
 * //=> [ 2020-01-01T00:00:00.000Z ]
 *
 * @example
 * range(new Date('2020-01-01'), new Date('2021-01-01'), O.some({ years: 1 }))
 * //=> [ 2020-01-01T00:00:00.000Z ]
 *
 * @param start start date of the range (inclusive)
 * @param end end date of the range (exclusive)
 * @param step duration between dates in the range
 * @returns an array of dates, from `start` to `end` (exclusive), with `step` duration
 *    between successive dates (empty if `start` is on or after `end`)
 */
export const range = (start: Date, end: Date, step: O.Option<dates.Duration>) => {
  const addStepTo = pipe(
    step,
    O.match(
      () => constant(end),
      (step: dates.Duration) => (date: Date) => dates.add(date, step)
    )
  );
  const nextDate = flow(
    O.fromPredicate((date: Date) => date < end),
    O.map((date) => [date, addStepTo(date)] as const)
  );

  return RA.unfold(start, nextDate);
};
