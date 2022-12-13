import * as dates from 'date-fns/fp';
import * as E from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';

export type DateFormat = { readonly DateFormat: unique symbol };

/**
 * Codec that narrows strings to those that represent [Unicode Date Format Patterns](
 * https://www.unicode.org/reports/tr35/tr35-dates.html#8-date-format-patterns).  This
 * doesn't provide true validation, but rather a naive assurance that a string is a date
 * format if a date can be formatted using the string as the date format, then parsed
 * using the string again as the date format, producing the same date as the original
 * input.
 */
export const DateFormat = new t.Type<string, string>(
  'DateFormat',
  (u): u is string => typeof u === 'string',
  (u, c) =>
    pipe(
      t.string.validate(u, c),
      E.chain(
        E.tryCatchK(
          unsafeValidatDateFormat,
          (e) => [{ value: u, context: c, message: (e as Error).message }] as t.Errors
        )
      ),
      E.chain((valid) => (valid ? t.success(String(u)) : t.failure(u, c)))
    ),
  t.identity
);

const unsafeValidatDateFormat = (s: string) => {
  // Given a format string (`s`), parsing a date string should be the inverse
  // of formatting a date: date -> format -> parse -> date.  If the result of
  // parsing is the same as the original input date, then we consider the
  // string (`s`) to be a DateFormat, if the string is non-empty.

  const options = { useAdditionalWeekYearTokens: true };
  const epoch = dates.parseISO('1970-01-01');
  const formattedEpoch = dates.formatWithOptions(options, s)(epoch);
  const parsedEpoch = dates.parseWithOptions(options, epoch, s, formattedEpoch);

  return s.length > 0 && dates.compareAsc(epoch, parsedEpoch) === 0;
};
