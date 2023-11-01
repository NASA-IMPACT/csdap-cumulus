/* eslint-disable functional/no-return-void */

import test from 'ava';

import { batchBounds } from './arrays';

//------------------------------------------------------------------------------
// slices
//------------------------------------------------------------------------------

test('slices should produce [[0, 0]] when totalLength == 0', (t) => {
  t.deepEqual(batchBounds({ totalSize: 0, maxBatchSize: 0 }), [[0, 0]]);
});

test('slices should produce [[0, 0]] when totalLength < 0', (t) => {
  t.deepEqual(batchBounds({ totalSize: -10, maxBatchSize: 10 }), [[0, 0]]);
});

test('slices should produce a singleton array when totalLength < maxSliceLength', (t) => {
  t.deepEqual(batchBounds({ totalSize: 100, maxBatchSize: 200 }), [[0, 100]]);
});

test('slices should produce a singleton array when totalLength == maxSliceLength', (t) => {
  t.deepEqual(batchBounds({ totalSize: 100, maxBatchSize: 100 }), [[0, 100]]);
});

test('slices should produce singleton slices when maxSliceLength <= 0', (t) => {
  t.deepEqual(batchBounds({ totalSize: 3, maxBatchSize: 0 }), [
    [0, 1],
    [1, 2],
    [2, 3],
  ]);
});

test('slices should produce slices of nearly equal lengths', (t) => {
  t.deepEqual(batchBounds({ totalSize: 100, maxBatchSize: 40 }), [
    [0, 34],
    [34, 67],
    [67, 100],
  ]);
});
