/* eslint-disable functional/no-this-expression */
import dayjs, { ManipulateType } from 'dayjs';
import customParseFormat from 'dayjs/plugin/customParseFormat';
import duration, { Duration } from 'dayjs/plugin/duration';
import utc from 'dayjs/plugin/utc';

declare module 'dayjs/plugin/duration' {
  interface Duration {
    readonly $d: {
      readonly years: number;
      readonly months: number;
      readonly weeks: number;
      readonly days: number;
      readonly hours: number;
      readonly minutes: number;
      readonly seconds: number;
    };
  }
}

const isDuration = (duration: unknown): duration is Duration =>
  Object.prototype.hasOwnProperty.call(duration, '$d') && dayjs.isDuration(duration);

dayjs.extend(customParseFormat);
dayjs.extend(duration);
dayjs.extend(utc);

// Override the `add` and `subtract` functions added by the `duration` extension, as
// they do not behave correctly in all cases.  For example, adding a duration of 1 month
// always adds 30 days, rather than simply rolling over the month (and year, if
// necessary) and keeping all other date/time components unchanged.  These overrides
// implement the correct behavior.
//
// For example, dayjs('2018-08-01').add('P1M') incorrectly produces a date of
// 2018-08-31, but should produce 2018-09-01.  The overrides below correct this.
//
// See issue https://github.com/iamkun/dayjs/issues/1515 and related PR
// https://github.com/iamkun/dayjs/pull/1513.  The following code is based on changes
// in the PR that address the issue.
dayjs.extend(
  // eslint-disable-next-line functional/no-return-void
  (_option: unknown, dayjsClass: typeof dayjs.Dayjs) => {
    const oldAdd = dayjsClass.prototype.add;
    const oldSubtract = dayjsClass.prototype.subtract;

    // eslint-disable-next-line functional/immutable-data
    dayjsClass.prototype.add = function (
      value: number | Duration,
      unit?: ManipulateType
    ) {
      return isDuration(value)
        ? Object.entries(value.$d).reduce(
            (d, [unit, n]) => d.add(n, unit as ManipulateType),
            this
          )
        : oldAdd.bind(this)(value, unit);
    };

    // eslint-disable-next-line functional/immutable-data
    dayjsClass.prototype.subtract = function (
      value: number | Duration,
      unit?: ManipulateType
    ) {
      return isDuration(value)
        ? Object.entries(value.$d).reduce(
            (d, [unit, n]) => d.subtract(n, unit as ManipulateType),
            this
          )
        : oldSubtract.bind(this)(value, unit);
    };
  }
);

/**
 * Extended `dayjs` function for convenience.  Throughout this repository, this should
 * be imported rather than importing the function directly from the dayjs library so
 * that the configured extensions can be used without fuss.
 */
export default dayjs;
