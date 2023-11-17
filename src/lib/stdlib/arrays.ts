type EllipsizeParams = {
  readonly head?: number;
  readonly tail?: number;
  readonly sep?: string;
};

/**
 * Returns an array of `[start, end]` number pairs suitable for slicing an array of
 * length `totalSize` into sequential, non-overlapping batches no longer than
 * `maxBatchSize` each.  Each pair is suitable for passing as the `start` and `end`
 * arguments to `Array.slice`, meaning that each `end` index is exclusive.
 *
 * Returned pairs are constructed such that difference between the maximum batch size
 * and the minimum batch size is no greater than 1.  In other words, the last batch is
 * not the only batch that can be smaller than `maxBatchSize`.  Rather, it is possible
 * that every batch is smaller than `maxBatchSize`.
 *
 * @example
 * batchBounds({ totalSize: 100, maxBatchSize: 50 })
 * //=> [[0, 50], [50, 100]]
 *
 * @example
 * batchBounds({ totalSize: 100, maxBatchSize: 40 })
 * // returns bounds of length 34, 33, and 33, NOT 40, 40, and 20
 * //=> [[0, 34], [34, 67], [67, 100]]
 *
 * @example
 * batchBounds({ totalSize: 100, maxBatchSize: 200 })
 * //=> [[0, 100]]
 *
 * @example
 * batchBounds({ totalSize: 100, maxBatchSize: 0 })
 * //=> [[0, 1], [1, 2], [2, 3], ..., [99, 100]]
 *
 * @param totalSize - total size (length) of an array to be split into batches
 * @param maxBatchSize - maximum size of any batch that can be produced from any pair
 *    of bounds in the returned array (set to 1 when a value less than 1 is specified)
 * @returns an array of start/end number pairs, each representing a sequential,
 *    non-overlapping batch of items no longer than `maxBatchSize` in length,
 *    spanning an array of length `totalSize`; [[0, 0]] when `totalSize <= 0`
 */
export const batchBounds = ({
  totalSize,
  maxBatchSize,
}: {
  readonly totalSize: number;
  readonly maxBatchSize: number;
}): readonly (readonly [number, number])[] => {
  const numBatches = Math.ceil(totalSize / Math.max(1, maxBatchSize));
  const minBatchSize = Math.floor(totalSize / numBatches);
  const remainder = totalSize % numBatches;

  return totalSize <= 0
    ? [[0, 0]]
    : [
        ...Array.from({ length: remainder }, () => minBatchSize + 1),
        ...Array.from({ length: numBatches - remainder }, () => minBatchSize),
      ]
        .reduce(
          ([[start = 0, end = 0] = [], ...rest], length) =>
            [[end, end + length], [start, end], ...rest] as const,
          [[0, 0]] as readonly (readonly [number, number])[]
        )
        .slice()
        .reverse()
        .slice(1); // drop leading [0, 0] bounds
};

/**
 * Splits an array of items into sequential, non-overlapping batches no longer than a
 * given size.  Each batch is a sequence of items from the original array, and each
 * batch is no longer than `n` in length.
 *
 * In particular, batches are not simply taken `n` at a time from the original array,
 * where the size of the last batch may be less than `n`.  Rather batches are created
 * using the bounds produced by the `batchBounds` function, which ensures that the
 * difference in size between the largest and smallest batch is no greater than 1.
 *
 * @example
 * batches([1, 2, 3, 4, 5, 6, 7, 8], 3)
 * //=> [[1, 2, 3], [4, 5, 6], [7, 8]]
 *
 * @param items - array of items to split into batches, maintaining order
 * @example
 * batches([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 2)
 * //=> [[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]]
 *
 * @example
 * batches([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 3)
 * //=> [[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]]
 * // Note that in this case we don't take 3 items at a time, as that would result in
 * // the last batch containing only 1 item, thus violating the constraint that the
 * // difference in size between the largest and smallest batch is no greater than 1.
 *
 * @example
 * batches([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 4)
 * //=> [[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]]
 * // Note that in this case we don't take 4 items at a time, as that would result in
 * // the last batch containing only 2 items, thus violating the constraint that the
 * // difference in size between the largest and smallest batch is no greater than 1.
 *
 * @example
 * batches([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 5)
 * //=> [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]]
 *
 * @param items - array of items to split into batches, maintaining order
 * @param n - maximum size of any batch
 * @returns an array of arrays of sequential elements of `items`, each no longer than
 *    `n` in length, and as evenly distributed in size as possible (the difference in
 *    size between the largest and smallest batch is no greater than 1)
 * @see batchBounds
 */
export const batches = <T>(items: readonly T[], n: number): readonly (readonly T[])[] =>
  batchBounds({ totalSize: items.length, maxBatchSize: n }).map(([start, end]) =>
    items.slice(start, end)
  );

/**
 * Similar to the built-in `join` array method, creates a string from items of an array,
 * separated by an optional separator.  Unlike the `join` method, however, items between
 * the head and tail may be elided and represented with an ellipsis when there are too
 * many items.
 *
 * @example
 * ellipsize([])
 * //=> ''
 *
 * @example
 * ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
 * //=> '1, 2, 3, 4, 5, 6, 7, 8, 9, 10'
 *
 * @example
 * ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
 * //=> '1, 2, 3, 4, 5, ..., 7, 8, 9, 10, 11'
 *
 * @example
 * ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], { head: 2 })
 * //=> '1, 2, ..., 6, 7, 8, 9, 10'
 *
 * @example
 * ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], { head: 2, tail: 2 })
 * //=> '1, 2, ..., 9, 10'
 *
 * @example
 * ellipsize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], { head: 2, tail: 2, sep: '|' })
 * //=> '1|2|...|9|10'
 *
 * @param items - array of items to join into a string
 * @param params.head - maximum number of items to include from the beginning of the
 *    array in the resulting string (default: 5)
 * @param params.tail - maximum number of items to include from the end of the array in
 *    the resulting string (default: 5)
 * @param params.sep - string to use as a separator between items (default: ', ')
 * @returns a string containing elements from `items`, separated by `params.sep`, taking
 *    at most `params.head` elements from the beginning of the array, at most
 *    `params.tail` elements from the end of the array, and including an ellipsis
 *    ('...') between the leading and trailing elements representing any additional
 *    elements (the ellipsis is excluded if there are no additional elements)
 */
export const ellipsize = <T>(items: readonly T[], params?: EllipsizeParams): string => {
  const { head = 5, tail = 5, sep = ', ' } = params ?? {};

  return items.length <= head + tail
    ? items.join(sep)
    : [...items.slice(0, head), '...', ...items.slice(items.length - tail)].join(sep);
};
