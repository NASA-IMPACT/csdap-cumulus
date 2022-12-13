import * as E from 'fp-ts/Either';
import { flow } from 'fp-ts/function';
import * as t from 'io-ts';
import * as PR from 'io-ts/PathReporter';

export * from './DateFormat';
export * from './DurationFromISOString';

export const toError = (es: t.Errors): Error => new Error(PR.failure(es).join(', '));

export const safeDecodeTo = <A>(codec: t.Type<A, unknown>) =>
  flow(codec.decode, E.mapLeft(toError));
