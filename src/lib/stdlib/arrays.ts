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
 *
 * @param items
 * @param n
 * @returns
 */
export const batches = <T>(items: readonly T[], n: number): readonly (readonly T[])[] =>
  batchBounds({ totalSize: items.length, maxBatchSize: n }).map(([start, end]) =>
    items.slice(start, end)
  );
