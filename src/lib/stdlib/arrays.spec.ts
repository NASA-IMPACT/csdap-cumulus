/* eslint-disable functional/no-return-void */

import test from 'ava';

import * as A from './arrays';

//------------------------------------------------------------------------------
// batchBounds
//------------------------------------------------------------------------------

test('batchBounds should produce [[0, 0]] when totalLength == 0', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: 0, maxBatchSize: 0 }), [[0, 0]]);
});

test('batchBounds should produce [[0, 0]] when totalLength < 0', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: -10, maxBatchSize: 10 }), [[0, 0]]);
});

test('batchBounds should produce a singleton array when totalLength < maxSliceLength', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: 100, maxBatchSize: 200 }), [[0, 100]]);
});

test('batchBounds should produce a singleton array when totalLength == maxSliceLength', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: 100, maxBatchSize: 100 }), [[0, 100]]);
});

test('batchBounds should produce single-step bounds when maxSliceLength <= 0', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: 3, maxBatchSize: 0 }), [
    [0, 1],
    [1, 2],
    [2, 3],
  ]);
});

test('batchBounds should produce bounds of nearly equal range sizes', (t) => {
  t.deepEqual(A.batchBounds({ totalSize: 100, maxBatchSize: 40 }), [
    [0, 34],
    [34, 67],
    [67, 100],
  ]);
});

//------------------------------------------------------------------------------
// ellipsize
//------------------------------------------------------------------------------

test('ellipsize should produce empty string for empty array', (t) => {
  t.deepEqual(A.ellipsize([]), '');
});

test('ellipsize should not include ellipsis with short array and default params', (t) => {
  t.deepEqual(
    A.ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
    '1, 2, 3, 4, 5, 6, 7, 8, 9, 10'
  );
});

test('ellipsize should include ellipsis with explicit params', (t) => {
  t.deepEqual(
    A.ellipsize([1, 2, 3, 4, 5], { head: 2, sep: '|', tail: 2 }),
    '1|2|...|4|5'
  );
});
