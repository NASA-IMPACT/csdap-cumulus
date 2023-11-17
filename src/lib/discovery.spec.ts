/* eslint-disable functional/no-return-void */
import test, { ExecutionContext } from 'ava';
import * as duration from 'duration-fns';
import * as E from 'fp-ts/Either';
import * as O from 'fp-ts/Option';
import { flow, pipe } from 'fp-ts/function';

import { DecodedEventHandler } from './aws/lambda';
import {
  batchGranules,
  formatProviderPaths,
  FormatProviderPathsInput,
  prefixGranuleIds,
  PrefixGranuleIdsInput,
} from './discovery';
import * as PR from './io/PathReporter';

//------------------------------------------------------------------------------
// Expected decoding failures
//------------------------------------------------------------------------------

const shouldFailToDecode = test.macro({
  title: (_, input) =>
    `ProviderPathInput should fail to decode ${JSON.stringify(input)}`,
  exec: (t: ExecutionContext, input, paths: readonly (readonly string[])[]) =>
    pipe(
      FormatProviderPathsInput.decode(input),
      E.match(
        (errors) => {
          const messages = PR.failure(errors);
          // Match all occurrences of '$.NAME' (excluding '$' with lookbehind)
          const actualPaths = messages.map((message) =>
            (message.match(/(?<=\$)[^\s]*/g) ?? []).join('')
          );
          const expectedPaths = paths.map((path) =>
            path.map((segment) => `.${segment}`).join('')
          );

          return t.deepEqual(actualPaths, expectedPaths, messages.join('\n'));
        },
        (output) => t.fail(`Unexpected output: ${JSON.stringify(output)}`)
      )
    ),
});

test(
  shouldFailToDecode,
  {
    meta: {
      providerPathFormat: 'planet/PSScene3Band-yyyyMM',
      startDate: '2018-08',
    },
  },
  [['meta', 'providerPathFormat']]
);

test(
  shouldFailToDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: 'hello',
    },
  },
  [['meta', 'startDate']]
);

test(
  shouldFailToDecode,
  {
    meta: {
      providerPathFormat: 'planet/PSScene3Band-yyyyMM',
      startDate: 'hello',
    },
  },
  [
    ['meta', 'providerPathFormat'],
    ['meta', 'startDate'],
  ]
);

test(
  shouldFailToDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '202101',
      endDate: 'never',
    },
  },
  [['meta', 'endDate']]
);

test(
  shouldFailToDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '202101',
      step: 'none',
    },
  },
  [['meta', 'step']]
);

//------------------------------------------------------------------------------
// Expected decoding successes
//------------------------------------------------------------------------------

const shouldDecode = test.macro({
  title: (_, input) =>
    `FormatProviderPathsInput should decode ${JSON.stringify(input)}`,
  exec: (t: ExecutionContext, input: unknown, expected: unknown) =>
    pipe(
      FormatProviderPathsInput.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (actual) => t.deepEqual(actual, expected)
      )
    ),
});

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      extraProperty: 'whatever',
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  {
    meta: {
      extraProperty: 'whatever',
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      endDate: undefined,
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2019-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      endDate: null,
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2019-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '202001',
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.some(new Date('202001')),
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2020-08',
      step: undefined,
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2020-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      step: null,
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2019-08'),
      endDate: O.none,
      step: O.none,
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      step: 'P1M',
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.none,
      step: O.some(duration.parse('P1M')),
    },
  }
);

test(
  shouldDecode,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '202001',
      step: 'P1M',
    },
  },
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.some(new Date('202001')),
      step: O.some(duration.parse('P1M')),
    },
  }
);

//------------------------------------------------------------------------------
// Expected formatProviderPaths outputs
//------------------------------------------------------------------------------

const formatProviderPathsShouldOutput = test.macro({
  title: (
    _,
    f: DecodedEventHandler<
      typeof FormatProviderPathsInput,
      FormatProviderPathsInput,
      unknown
    >,
    input
  ) => `${f.name} should succeed with input ${JSON.stringify(input)}`,
  exec: (
    t: ExecutionContext,
    f: DecodedEventHandler<
      typeof FormatProviderPathsInput,
      FormatProviderPathsInput,
      unknown
    >,
    input: unknown,
    expected: unknown
  ) =>
    pipe(
      FormatProviderPathsInput.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (event) => t.deepEqual(f(event), expected)
      )
    ),
});

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'css/nga/WV04/1B/'yyyy/DDD",
      startDate: '2017-05-04T00:00:00Z',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'css/nga/WV04/1B/'yyyy/DDD",
        providerPath: 'css/nga/WV04/1B/2017/124',
        startDate: '2017-05-04T00:00:00.000Z',
        endDate: null,
        step: null,
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'css/nga/WV04/1B/'yyyy/D/",
      startDate: '2017-01-04T00:00:00Z',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'css/nga/WV04/1B/'yyyy/D/",
        providerPath: 'css/nga/WV04/1B/2017/4/',
        startDate: '2017-01-04T00:00:00.000Z',
        endDate: null,
        step: null,
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM_dd",
      startDate: '2018-08-01T00:00:00Z',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM_dd",
        providerPath: 'planet/PSScene3Band-201808_01',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: null,
        step: null,
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201808',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: null,
        step: null,
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2018-08-01T00:00:00Z',
    },
  },
  []
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    payload: {},
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2018-09-01T00:00:00Z',
      foo: 'bar',
    },
  },
  [
    {
      payload: {},
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201808',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2018-09-01T00:00:00.000Z',
        step: null,
        foo: 'bar',
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2020-12-01T00:00:00Z',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201808',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2020-12-01T00:00:00.000Z',
        step: null,
      },
    },
  ]
);

test(
  formatProviderPathsShouldOutput,
  formatProviderPaths,
  {
    meta: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2018-12-01T00:00:00Z',
      step: 'P1M',
    },
  },
  [
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201808',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2018-12-01T00:00:00.000Z',
        step: 'P1M',
      },
    },
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201809',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2018-12-01T00:00:00.000Z',
        step: 'P1M',
      },
    },
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201810',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2018-12-01T00:00:00.000Z',
        step: 'P1M',
      },
    },
    {
      meta: {
        providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
        providerPath: 'planet/PSScene3Band-201811',
        startDate: '2018-08-01T00:00:00.000Z',
        endDate: '2018-12-01T00:00:00.000Z',
        step: 'P1M',
      },
    },
  ]
);

//------------------------------------------------------------------------------
// prefixGranuleIds
//------------------------------------------------------------------------------

test('prefixGranuleIds should prefix granule IDs with collection name', (t) => {
  const collectionName = 'PSScene3Band';
  const granule = {
    granuleId: 'abc',
    files: [],
  };
  const expected = {
    granules: [
      {
        ...granule,
        granuleId: `${collectionName}-${granule.granuleId}`,
      },
    ],
  };
  const event = {
    config: { collection: { name: collectionName }, batchIndex: 0 },
    input: { granules: [granule] },
  };

  return pipe(
    PrefixGranuleIdsInput.decode(event),
    E.match(
      (e) => t.fail(`Unexpected error(s): ${e}`),
      flow(prefixGranuleIds, (actual) => t.deepEqual(actual, expected))
    )
  );
});

//------------------------------------------------------------------------------
// batchGranules
//------------------------------------------------------------------------------

test('batchGranules should output singleton array identical to input when there are no granules', (t) => {
  const actual = batchGranules({
    config: { providerPath: 'foo', maxBatchSize: 0 },
    input: { granules: [] },
  });
  const expected = [{ granules: [] }];

  t.deepEqual(actual, expected);
});

test('batchGranules should output a singleton array identical to input when there are no more than 1000 granules', (t) => {
  const actual = batchGranules({
    config: { providerPath: 'foo', maxBatchSize: 0 },
    input: { granules: [{ granuleId: 'foo' }] },
  });
  const expected = [{ granules: [{ granuleId: 'foo' }] }];

  t.deepEqual(actual, expected);
});

test('batchGranules should output array with nearly equally sized batches when there are over maxBatchSize granules', (t) => {
  const granules = Array.from({ length: 100 }, (_, i) => ({ granuleId: `${i}` }));
  const batch1 = granules.slice(0, 34);
  const batch2 = granules.slice(34, 67);
  const batch3 = granules.slice(67, 100);
  const actual = batchGranules({
    config: { providerPath: 'foo', maxBatchSize: 40 },
    input: { granules },
  });
  const expected = [{ granules: batch1 }, { granules: batch2 }, { granules: batch3 }];

  t.deepEqual(actual, expected);
});
