import * as L from 'aws-lambda';
import * as E from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as PR from 'io-ts/PathReporter';

export type AsyncHandler<E, R> = (event: E, context: L.Context) => Promise<R>;
export type PropsHandler<C extends t.Any, P extends t.TypeOf<C>, R> = {
  (props: P): R | Promise<R>;
};

/**
 * Convenience function for wrapping a typed handler within an AWS Lambda Function
 * handler.  Enables decoupling primary logic from parsing/validation logic at the
 * system boundary.
 *
 * @example
 * const MyProps = t.type(...);
 * type MyProps = t.TypeOf<typeof MyProps>;
 *
 * // May be sync or async
 * function handleMyProps(props: MyProps) {
 *   // ...
 * }
 *
 * // Export as handler for AWS Lambda Function
 * export handler = mkAsyncHandler(MyProps)(handleMyProps);
 *
 * @param codec - Codec for decoding an encoded input
 * @returns a function that accepts a PropsHandler and returns an async AWS Lambda
 *   function handler
 */
export const mkAsyncHandler =
  <C extends t.Any>(codec: C) =>
  <I extends t.TypeOf<C>, R>(h: PropsHandler<C, I, R>): AsyncHandler<unknown, R> =>
  async (event: unknown) =>
    pipe(
      codec.decode(event),
      E.match(
        (errors) => Promise.reject(new Error(PR.failure(errors).join('\n'))),
        (decoded) => Promise.resolve(h(decoded))
      )
    );

export { Context } from 'aws-lambda';
