import test, { ExecutionContext } from 'ava';
import * as duration from 'duration-fns';
import * as E from 'fp-ts/Either';
import * as O from 'fp-ts/Option';
import { flow, pipe } from 'fp-ts/function';

import { DecodedEventHandler } from './aws/lambda';
import {
  advanceStartDate,
  formatProviderPath,
  prefixGranuleIds,
  PrefixGranuleIdsInput,
  ProviderPathInput,
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
      ProviderPathInput.decode(input),
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

const shouldDecode = test.macro({
  title: (_, input) => `ProviderPathInput should decode ${JSON.stringify(input)}`,
  exec: (t: ExecutionContext, input: unknown, expected: unknown) =>
    pipe(
      ProviderPathInput.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (actual) => t.deepEqual(actual, expected)
      )
    ),
});

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

const shouldOutput = test.macro({
  title: (
    _,
    f: DecodedEventHandler<typeof ProviderPathInput, ProviderPathInput, unknown>,
    input
  ) => `${f.name} should succeed with input ${JSON.stringify(input)}`,
  exec: (
    t: ExecutionContext,
    f: DecodedEventHandler<typeof ProviderPathInput, ProviderPathInput, unknown>,
    input: unknown,
    expected: unknown
  ) =>
    pipe(
      ProviderPathInput.decode(input),
      E.match(
        (errors) => t.fail(PR.failure(errors).join('\n')),
        (event) => t.deepEqual(f(event), expected)
      )
    ),
});

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'css/nga/WV04/1B/'yyyy/DDD",
      startDate: '2017-05-04T00:00:00Z',
    },
  },
  'css/nga/WV04/1B/2017/124'
);

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'css/nga/WV04/1B/'yyyy/D/",
      startDate: '2017-01-04T00:00:00Z',
    },
  },
  'css/nga/WV04/1B/2017/4/'
);

test(
  shouldOutput,
  formatProviderPath,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM_dd",
      startDate: '2018-08-01T00:00:00Z',
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
      startDate: '2018-08-01T00:00:00Z',
    },
  },
  'planet/PSScene3Band-201808'
);

//------------------------------------------------------------------------------
// Expected advanceStartDate outputs
//------------------------------------------------------------------------------

test(
  shouldOutput,
  advanceStartDate,
  {
    config: {
      providerPathFormat: "'planet/PSScene3Band-'yyyyMM",
      startDate: '2018-08-01T00:00:00Z',
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
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2021-09-01T00:00:00Z',
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
      startDate: '2018-08-01T00:00:00Z',
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
      startDate: '2018-09-01T00:00:00Z',
      endDate: '2020-01-01T00:00:00Z',
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
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2018-09-01T00:00:00Z', // endDate is exclusive
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
      startDate: '2018-08-01T00:00:00Z',
      endDate: '2020-01-01T00:00:00Z',
      step: 'P1Y',
    },
  },
  '2019-08-01T00:00:00.000Z'
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
    config: { collection: { name: collectionName } },
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
