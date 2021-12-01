/* eslint-disable functional/no-return-void */
import test from 'ava';
import dayjs from 'dayjs';
import * as E from 'fp-ts/Either';
import * as PR from 'io-ts/PathReporter';

import * as $t from '.';

test('should fail to decode undefined', (t) => {
  const result = $t.DurationFromISOString.decode(undefined);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value undefined supplied to : DurationFromISOString'])
  );
});

test('should fail decode a number', (t) => {
  const result = $t.DurationFromISOString.decode(0);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value 0 supplied to : DurationFromISOString'])
  );
});

test('should fail to decode an empty string', (t) => {
  const result = $t.DurationFromISOString.decode('');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value "" supplied to : DurationFromISOString'])
  );
});

test('should fail to decode an invalid ISO Duration string', (t) => {
  const result = $t.DurationFromISOString.decode('P1m');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value "P1m" supplied to : DurationFromISOString'])
  );
});

test('should decode a valid ISO Duration string', (t) => {
  const result = $t.DurationFromISOString.decode('P1M');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.right(
      dayjs.duration({
        years: 0,
        months: 1,
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
      })
    )
  );
});
