/**
 * Returns the specified synchronous function wrapped in another synchronous function
 * with the same signature, which traces the arguments and return value upon invocation.
 * If the specified function throws an exception upon invocation, propagates the
 * exception.
 *
 * @example
 * > const add = (x, y) => x + y
 * undefined
 * > const traceAdd = trace(add)
 * undefined
 * > traceAdd(1, 2)
 * -> add(1, 2)
 * <- 3
 * 3
 * > traceAdd('hello', 'world')
 * -> add("hello", "world")
 * <- "helloworld"
 * helloworld
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
 * > const addAsync = async (x, y) => x + y;
 * undefined
 * > const traceAddAsync = trace(addAsync);
 * undefined
 * > traceAddAsync(1, 2);
 * -> addAsync(1, 2)
 * <- 3
 * 3  // Promise
 *
 * > traceAddAsync('hello', 'world');
 * -> addAsync("hello", "world")
 * <- "helloworld"
 * helloworld  // Promise
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
