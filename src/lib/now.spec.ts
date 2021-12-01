/* eslint-disable functional/no-return-void */
import anyTest, { TestInterface } from 'ava'; // AVA 3
// import anyTest, {TestFn as TestInterface} from 'ava'; // AVA 4, usage is the same

type Context = {
  // eslint-disable-next-line functional/prefer-readonly-type
  now: () => number;
};

const test = anyTest as TestInterface<Context>;

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

test('noop', (t) => t.pass());
