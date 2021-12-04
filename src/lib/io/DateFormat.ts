import * as t from 'io-ts';

import dayjs from '../dayjs';

export type DateFormatBrand = { readonly DateFormat: unique symbol };
export type DateFormat = t.Branded<string, DateFormatBrand>;
export type DateFormatC = t.Type<DateFormat, string, unknown>;

/**
 * Codec that narrows strings to those that represent date formats.  This doesn't
 * provide true validation, but rather a naive assurance that a string is a date
 * format if a date can be formatted using the string as the date format, then parsed
 * using the string again as the date format, producing the same date as the original
 * input.
 *
 * See the [Day.js Format specification](https://day.js.org/docs/en/display/format).
 */
export const DateFormat: DateFormatC = t.brand(
  t.string,
  (s): s is DateFormat => {
    // Given a format string (`s`), parsing a date string should be the inverse
    // of formatting a date: date -> format -> parse -> date.  If the result of
    // parsing is the same as the original input date, then we consider the
    // string (`s`) to be a DateFormat, if the string is non-empty.

    const epoch = dayjs.utc(0);
    const parsedEpoch = dayjs.utc(epoch.format(s), s);

    return s.length > 0 && parsedEpoch.isSame(epoch);
  },
  'DateFormat'
);
