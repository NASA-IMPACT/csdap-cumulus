/* eslint-disable functional/no-return-void */

import test from 'ava';
import * as O from 'fp-ts/Option';

import { range } from './dates';

//------------------------------------------------------------------------------
// range
//------------------------------------------------------------------------------

test('range should produce empty array when start == end', (t) => {
  const r = range(
    new Date('2020-01-01'),
    new Date('2020-01-01'),
    O.some({ months: 1 })
  );

  t.deepEqual(r, []);
});

test('range should produce empty array when start > end', (t) => {
  const r = range(
    new Date('2020-02-01'),
    new Date('2020-01-01'),
    O.some({ months: 1 })
  );

  t.deepEqual(r, []);
});

test('range should exclude end', (t) => {
  const r = range(
    new Date('2020-01-01'),
    new Date('2020-02-01'),
    O.some({ months: 1 })
  );

  t.deepEqual(r, [new Date('2020-01-01')]);
});

test('range should space dates by step', (t) => {
  const r = range(
    new Date('2020-01-01'),
    new Date('2020-03-01'),
    O.some({ months: 1 })
  );

  t.deepEqual(r, [new Date('2020-01-01'), new Date('2020-02-01')]);
});

test('range should make single step when step not given', (t) => {
  const r = range(new Date('2020-01-01'), new Date('2020-03-01'), O.none);

  t.deepEqual(r, [new Date('2020-01-01')]);
});
