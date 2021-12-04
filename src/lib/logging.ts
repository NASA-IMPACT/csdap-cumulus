/**
 * Returns the specified synchronous function wrapped in another synchronous function
 * with the same signature, which traces the arguments and return value upon invocation.
 * If the specified function throws an exception upon invocation, propagates the
 * exception.
 *
 * @example
 * const add = (x, y) => x + y;
 * const traceAdd = trace(add);
 *
 * traceAdd(1, 2); // returns 3
 * // writes bhe following:
 * // -> add(1, 2)
 * // <- 3
 *
 * traceAdd('hello', 'world'); // returns 'helloworld'
 * // writes the following:
 * // -> add("hello", "world")
 * // <- "helloworld"
 *
 * @param f - function to trace
 * @returns tracing function with same signature as specified function
 */
export const trace =
  <T extends readonly unknown[], U>(f: (...args: T) => U) =>
  // eslint-disable-next-line functional/functional-parameters
  (...args: T): U => {
    const stringifiedArgs = args.map((arg) => JSON.stringify(arg)).join(', ');
    console.debug(`-> ${f.name || 'function '}(${stringifiedArgs})`);
    const result = f(...args);
    console.debug(`<- ${JSON.stringify(result)}`);

    return result;
  };

/**
 * Returns the specified asynchronous function wrapped in another asynchronous function
 * with the same signature, which traces the arguments and return value upon invocation.
 * If the specified function throws an exception upon invocation, propagates the
 * exception.
 *
 * @example
 * const addAsync = async (x, y) => x + y;
 * const traceAddAsync = trace(addAsync);
 *
 * await traceAddAsync(1, 2); // returns 3
 * // writes bhe following:
 * // -> addAsync(1, 2)
 * // <- 3
 *
 * await traceAddAsync('hello', 'world'); // returns 'helloworld'
 * // writes the following:
 * // -> addAsync("hello", "world")
 * // <- "helloworld"
 *
 * @param f - async function to trace
 * @returns async tracing function with same signature as specified function
 */
export const traceAsync =
  <T extends readonly unknown[], U>(f: (...args: T) => Promise<U>) =>
  // eslint-disable-next-line functional/functional-parameters
  async (...args: T): Promise<U> => {
    const stringifiedArgs = args.map((arg) => JSON.stringify(arg)).join(', ');
    console.debug(`-> ${f.name || 'function '}(${stringifiedArgs})`);
    const result = await f(...args);
    console.debug(`<- ${JSON.stringify(result)}`);

    return result;
  };
