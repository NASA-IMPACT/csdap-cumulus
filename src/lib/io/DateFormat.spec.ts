/* eslint-disable functional/no-return-void */
import test from 'ava';
import * as E from 'fp-ts/Either';

import * as PR from './PathReporter';

import * as $t from '.';

test('should fail to decode nullish value', (t) => {
  const result = $t.DateFormat.decode(null);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DateFormat: null'])
  );
});

test('should fail to decode an empty string', (t) => {
  const result = $t.DateFormat.decode('');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DateFormat: ""'])
  );
});

test('should fail to decode a non-nullish, non-string value', (t) => {
  const result = $t.DateFormat.decode(0);

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DateFormat: 0'])
  );
});

test('should fail to decode "hello"', (t) => {
  const result = $t.DateFormat.decode('hello');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DateFormat: "hello"'])
  );
});

test('should fail to decode "yyyy"', (t) => {
  const result = $t.DateFormat.decode('yyyy');

  t.deepEqual(
    E.mapLeft(PR.failure)(result),
    E.left(['Invalid value for type DateFormat: "yyyy"'])
  );
});

test('should decode "[escaped]-YYYYMM"', (t) => {
  const result = $t.DateFormat.decode('[escaped]-YYYYMM');

  t.deepEqual(result, E.right('[escaped]-YYYYMM'));
});
