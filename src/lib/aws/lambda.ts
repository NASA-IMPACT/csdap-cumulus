import * as CMA from '@cumulus/cumulus-message-adapter-js';
import * as M from '@cumulus/types/message';
import * as L from 'aws-lambda';
import * as E from 'fp-ts/Either';
import { pipe } from 'fp-ts/function';
import * as t from 'io-ts';

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
 * export handler = mkAsyncHandler(DecodedEvent)(handleDecodedEvent);
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
    await pipe(event, safeDecodeTo(codec), E.match(Promise.reject, handler));

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
 * import * as cma from './cma';
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
 * export const handler = CMA.asyncHandler(internalHandler);
 *
 * @param handler - an async AWS Lambda Function handler
 * @returns an async AWS Lambda Function handler that wraps the specified "vanilla"
 *    handler for use with the Cumulus Message Adapter (CMA)
 */
export const cmaAsyncHandler =
  <E, R>(handler: AsyncHandler<E, R>) =>
  async (event: CMAEvent, context: L.Context): Promise<CMAResult> =>
    await CMA.runCumulusTask(handler, event, context);
