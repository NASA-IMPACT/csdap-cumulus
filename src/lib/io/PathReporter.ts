import { fold } from 'fp-ts/lib/Either';
import { Context, getFunctionName, ValidationError } from 'io-ts';
import { Reporter } from 'io-ts/Reporter';

function stringify(v: unknown): string {
  if (typeof v === 'function') return getFunctionName(v);
  if (typeof v === 'number' && !isFinite(v)) return String(v);
  return JSON.stringify(v);
}

function jsonPath(context: Context): string {
  return context.map(({ key }) => key || '$').join('.');
}

function expectedType(context: Context): string {
  return context.length === 0 ? 'unknown' : context[context.length - 1].type.name;
}

function getMessage(e: ValidationError): string {
  const path = e.context.length < 2 ? '' : ` at path ${jsonPath(e.context)}`;
  const type = expectedType(e.context);
  const value = stringify(e.value);
  const defaultMessage = `Invalid value${path} for type ${type}: ${value}`;

  return e.message ? `${defaultMessage}: ${e.message}` : defaultMessage;
}

export function failure(es: ReadonlyArray<ValidationError>): ReadonlyArray<string> {
  return es.map(getMessage);
}

export function success(): ReadonlyArray<string> {
  return [];
}

export const PathReporter: Reporter<ReadonlyArray<string>> = {
  report: fold(failure, success),
};
