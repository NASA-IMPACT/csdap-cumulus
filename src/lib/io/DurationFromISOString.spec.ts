/* eslint-disable functional/no-return-void */
import test from 'ava';
import * as E from 'fp-ts/lib/Either';

import * as PR from './PathReporter';

import * as $t from '.';

test('should fail to decode undefined', (t) => {
  const result = $t.DurationFromISOString.decode(undefined);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DurationFromISOString: undefined'])
  );
});

test('should fail decode a number', (t) => {
  const result = $t.DurationFromISOString.decode(0);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DurationFromISOString: 0'])
  );
});

test('should fail to decode an empty string', (t) => {
  const result = $t.DurationFromISOString.decode('');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DurationFromISOString: ""'])
  );
});

test('should fail to decode an invalid ISO Duration string', (t) => {
  const result = $t.DurationFromISOString.decode('P1m');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left([
      'Invalid value for type DurationFromISOString: "P1m":' +
        ' Failed to parse duration. "P1m" is not a valid ISO duration string.',
    ])
  );
});

test('should decode a valid ISO Duration string', (t) => {
  const result = $t.DurationFromISOString.decode('P1M');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.right({
      years: 0,
      months: 1,
      weeks: 0,
      days: 0,
      hours: 0,
      minutes: 0,
      seconds: 0,
      milliseconds: 0,
    })
  );
});
