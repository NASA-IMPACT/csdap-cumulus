/* eslint-disable functional/no-return-void */
import test, { ExecutionContext } from 'ava';
import * as duration from 'duration-fns';
import * as E from 'fp-ts/Either';
import * as O from 'fp-ts/Option';
import { pipe } from 'fp-ts/function';
import * as fp from 'lodash/fp';

import {
  advanceStartDate,
  discoverGranulesPrefixingIds,
  formatProviderPath,
  prefixGranuleIds,
  ProviderPathProps,
} from './discovery';
import * as PR from './io/PathReporter';
import { PropsHandler } from './lambda';

const shouldDecode = test.macro({
  title: (_, input) => `should decode ${JSON.stringify(input)}`,
  exec: (t: ExecutionContext, input: unknown, expected: unknown) =>
    pipe(
      ProviderPathProps.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (actual) => t.deepEqual(actual, expected)
      )
    ),
});

const shouldFailToDecode = test.macro({
  title: (_, input) => `should fail to decode ${JSON.stringify(input)}`,
  exec: (t: ExecutionContext, input, paths: readonly (readonly string[])[]) =>
    pipe(
      ProviderPathProps.decode(input),
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

          t.deepEqual(actualPaths, expectedPaths, messages.join('\n'));
        },
        (output) => t.fail(`Unexpected output: ${JSON.stringify(output)}`)
      )
    ),
});

const shouldOutput = test.macro({
  title: (
    _,
    f: PropsHandler<typeof ProviderPathProps, ProviderPathProps, unknown>,
    input
  ) => `should successfully compute ${f.name}(${JSON.stringify(input)})`,
  exec: (
    t: ExecutionContext,
    f: PropsHandler<typeof ProviderPathProps, ProviderPathProps, unknown>,
    input: unknown,
    expected: unknown
  ) =>
    pipe(
      ProviderPathProps.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (event) => t.deepEqual(f(event), expected)
      )
    ),
});

//------------------------------------------------------------------------------

test('prefixGranuleIds should prefix granule IDs with collection name', (t) => {
  const collectionName = 'PSScene3Band';
  const payload = {
    granules: [
      {
        granuleId: 'abc',
      },
      {
        granuleId: '123',
      },
    ],
  };
  const expectedPayload = {
    granules: payload.granules.map(({ granuleId }) => ({
      granuleId: `${collectionName}-${granuleId}`,
    })),
  };
  const actualPayload = prefixGranuleIds(collectionName)(payload);

  t.deepEqual(actualPayload, expectedPayload);
  t.is(actualPayload.granules, payload.granules);
  payload.granules.forEach((granule, i) => t.is(actualPayload.granules[i], granule));
});

//------------------------------------------------------------------------------
// Expected decoding failures
//------------------------------------------------------------------------------

test(
  shouldFailToDecode,
  {
    config: {
      providerPathFormat: 'planet/PSScene3Band-yyyyMM',
      startDate: '2018-08',
    },
  },
  [['config', 'providerPathFormat']]
);

test(
  shouldFailToDecode,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: 'hello',
    },
  },
  [['config', 'startDate']]
);

test(
  shouldFailToDecode,
  {
    config: {
      providerPathFormat: 'planet/PSScene3Band-yyyyMM',
      startDate: 'hello',
    },
  },
  [
    ['config', 'providerPathFormat'],
    ['config', 'startDate'],
  ]
);

test(
  shouldFailToDecode,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '202101',
      endDate: 'never',
    },
  },
  [['config', 'endDate']]
);

test(
  shouldFailToDecode,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '202101',
      step: 'none',
    },
  },
  [['config', 'step']]
);

//------------------------------------------------------------------------------
// Expected decoding successes
//------------------------------------------------------------------------------

test(
  shouldDecode,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  {
    config: {
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
    config: {
      extraProperty: 'whatever',
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      endDate: undefined,
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      endDate: null,
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '202001',
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2020-08',
      step: undefined,
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2019-08',
      step: null,
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      step: 'P1M',
    },
  },
  {
    config: {
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
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '202001',
      step: 'P1M',
    },
  },
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: new Date('2018-08'),
      endDate: O.some(new Date('202001')),
      step: O.some(duration.parse('P1M')),
    },
  }
);

//------------------------------------------------------------------------------
// Expected formatProviderPath outputs
//------------------------------------------------------------------------------

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'css/nga/WV04/1B/'yyyy/DDD",
      startDate: '2017-05-04',
    },
  },
  'css/nga/WV04/1B/2017/124'
);

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM_dd",
      startDate: '2018-08',
    },
  },
  'planet/PSScene3Band-201808_01'
);

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  'planet/PSScene3Band-201808'
);

//------------------------------------------------------------------------------
// Expected updateStartDate outputs
//------------------------------------------------------------------------------

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
    },
  },
  null
);

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '2021-09',
      step: null,
    },
  },
  null
);

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: null,
      step: 'P1M',
    },
  },
  '2018-09-01T00:00:00.000Z'
);

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-09',
      endDate: '2020-01',
      step: 'P1M',
    },
  },
  '2018-10-01T00:00:00.000Z'
);

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '2018-09', // endDate is exclusive
      step: 'P1M',
    },
  },
  null
);

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08',
      endDate: '2020-01',
      step: 'P1Y',
    },
  },
  '2019-08-01T00:00:00.000Z'
);

const discoveredGranules = {
  granules: [
    {
      granuleId: 'Bar',
    },
  ],
};

test('discovery should prefix granule IDs', async (t) => {
  const name = 'Foo';
  const actual = await discoverGranulesPrefixingIds(() =>
    Promise.resolve(fp.cloneDeep(discoveredGranules))
  )({
    config: {
      collection: {
        name,
        meta: { prefixGranuleIds: true },
      },
    },
  });

  t.deepEqual(actual, prefixGranuleIds(name)(discoveredGranules));
});

test('discovery should not prefix granule IDs', async (t) => {
  const actual = await discoverGranulesPrefixingIds(() =>
    Promise.resolve(fp.cloneDeep(discoveredGranules))
  )({
    config: {
      collection: {
        name: 'Foo',
        meta: { prefixGranuleIds: true },
      },
    },
  });

  t.deepEqual(actual, discoveredGranules);
});
