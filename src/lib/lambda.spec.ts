/* eslint-disable functional/no-return-void */
import test from 'ava';
import * as tt from 'io-ts-types';

import * as L from './lambda';

const emptyContext: L.Context = Object.freeze({
  callbackWaitsForEmptyEventLoop: false,
  functionName: '',
  functionVersion: '',
  invokedFunctionArn: '',
  memoryLimitInMB: '',
  awsRequestId: '',
  logGroupName: '',
  logStreamName: '',
  getRemainingTimeInMillis: (): number => 0,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  done: (_error?: Error, _result?: unknown): void => void 0,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  fail: (_error: string | Error): void => void 0,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  succeed: (_messageOrObject: unknown): void => void 0,
});

test('mkAsyncHandler should make an async handler', async (t) => {
  const handler = L.mkAsyncHandler(tt.NumberFromString)((n: number) => n + 1);
  const actual = await handler('41', emptyContext);

  t.is(actual, 42);
});
