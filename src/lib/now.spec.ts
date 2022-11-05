/* eslint-disable functional/no-return-void */
import anyTest, { TestFn } from 'ava';

type Context = {
  // eslint-disable-next-line functional/prefer-readonly-type
  now: () => number;
};

const test = anyTest as TestFn<Context>;

test.beforeEach((t) => {
  // Stub out Date.now() so we can test against fixed Date values.
  const now = Date.now();
  [t.context.now, Date.now] = [Date.now, () => now];
});

test.afterEach.always((t) => {
  // Restore original Date.now() function.
  // eslint-disable-next-line functional/immutable-data
  Date.now = t.context.now;
});

// To allow mocking the current time, code under test should obtain the current
// date/time by using `new Date(Date.now())`.  Although using `new Date()` (i.e.,
// without an argument) produces the current date/time, it does not allow mocking.

test('noop', (t) => t.pass());
