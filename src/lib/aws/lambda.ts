import * as CMA from '@cumulus/cumulus-message-adapter-js';
import * as M from '@cumulus/types/message';
import * as L from 'aws-lambda';
import * as E from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';
import * as fp from 'lodash/fp';

import { safeDecodeTo } from '../io';

type CMAEvent = CMA.CMAMessage | M.CumulusMessage | M.CumulusRemoteMessage;
type CMAResult = CMA.CumulusMessageWithAssignedPayload | M.CumulusRemoteMessage;

export type AsyncHandler<A, B> = (event: A, context: L.Context) => Promise<B>;
export type DecodedEventHandler<C extends t.Any, A extends t.TypeOf<C>, B> = {
  (event: A): B | Promise<B>;
};

/**
 * Convenience function for wrapping a typed handler within an AWS Lambda Function
 * handler.  Enables decoupling primary logic from parsing/validation logic at the
 * system boundary.
 *
 * @example
 * const DecodedEvent = t.type(...);
 * type DecodedEvent = t.TypeOf<typeof DecodedEvent>;
 *
 * // May be sync or async
 * function handleDecodedEvent(event: DecodedEvent) {
 *   // ...
 * }
 *
 * // Export as handler for AWS Lambda Function
 * export handler = pipe(handleDecodedEvent, asyncHandlerFor(DecodedEvent));
 *
 * @param codec - Codec for decoding an encoded event
 * @returns a function that accepts a DecodedEventHandler and returns an async AWS
 *    Lambda function handler
 */
export const asyncHandlerFor =
  <C extends t.Any>(codec: C) =>
  <A extends t.TypeOf<C>, B>(
    handler: DecodedEventHandler<C, A, B>
  ): AsyncHandler<unknown, B> =>
  async (event: unknown) =>
    await pipe(
      event,
      safeDecodeTo(codec),
      E.match((e) => Promise.reject(e), handler)
    );

/**
 * Convenience function for wrapping a "vanilla" async AWS Lambda Function handler
 * for use with the Cumulus Message Adapter (CMA).
 *
 * Using the returned wrapper handler requires that the CMA lambda layer is deployed,
 * and that the associated StepFunction Lambda task is configured with a `"cma"`
 * Parameter.
 *
 * @example
 * // Terraform state machine definition
 * "MyStep": {
 *   "Type": "Task",
 *   "Parameters": {
 *     "cma": {
 *       ...,
 *       "task_config": {
 *         "provider": "{$.meta.provider}",
 *         ...,
 *       }
 *     }
 *   },
 *   ...,
 * }
 *
 * // Import this module
 * import * as L from './aws/lambda';
 *
 * // Define event type based upon task_config in state machine definition
 * type Event = {
 *   config: {
 *     provider: {
 *       ...
 *     }
 *   },
 *   ...,
 * }
 *
 * // Export internal handler for testing
 * export async function internalHandler(event: Event, context: Context) {
 *   const { provider } = event.config;
 *   ...
 * }
 *
 * // Export wrapped handler to configure as the AWS Lambda Function handler
 * export const handler = L.cmaAsyncHandler(internalHandler);
 *
 * @param handler - an async AWS Lambda Function handler
 * @returns an async AWS Lambda Function handler that wraps the specified "vanilla"
 *    handler for use with the Cumulus Message Adapter (CMA)
 */
export const cmaAsyncHandler =
  <A, B>(handler: AsyncHandler<A, B | ReadonlyArray<B>>) =>
  async (
    event: CMAEvent,
    context: L.Context
  ): Promise<CMAResult | readonly CMAResult[]> => {
    // eslint-disable-next-line functional/no-let
    let handlerResult: B | ReadonlyArray<B> | undefined = undefined;

    const handlerWrapper = async (event: A, context: L.Context) =>
      // Capture the original result returned by the handler so we can inspect it after
      // CMA.runCumulusTask returns to see whether or not the handler produced an array.
      (handlerResult = await handler(event, context));
    const result = await CMA.runCumulusTask(handlerWrapper, event, context);

    // If the handler produced an array, that means we want to also return an array
    // from this function.  The resulting array is of the same length as the array
    // produced by the handler, each element being a copy of the CMA result, along with
    // a 0-based meta.batchIndex value corresponding to the item's index within the
    // array.  This is so that a corresponding "unbatch" handler can select individual
    // batches for use with a Map state for parallelizing batch processing.

    return Array.isArray(handlerResult)
      ? Array.from(handlerResult, (_, i) => fp.set(['meta', 'batchIndex'], i, result))
      : result;
  };
