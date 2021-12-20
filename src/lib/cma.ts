import * as CMA from '@cumulus/cumulus-message-adapter-js';
import * as M from '@cumulus/types/message';

import * as L from './lambda';

export type CMAEvent = CMA.CMAMessage | M.CumulusMessage | M.CumulusRemoteMessage;
export type CMAResult = CMA.CumulusMessageWithAssignedPayload | M.CumulusRemoteMessage;
export type CMAAsyncHandler = L.AsyncHandler<CMAEvent, CMAResult>;

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
 * export const handler = asyncHandler(internalHandler);
 *
 * @param handler - an async AWS Lambda Function handler
 * @returns an async AWS Lambda Function handler that wraps the specified "vanilla"
 *    handler for use with the Cumulus Message Adapter (CMA)
 */
export const asyncHandler =
  <E, R>(handler: L.AsyncHandler<E, R>) =>
  (event: CMAEvent, context: L.Context): Promise<CMAResult> =>
    CMA.runCumulusTask(handler, event, context);

export * from '@cumulus/cumulus-message-adapter-js';
