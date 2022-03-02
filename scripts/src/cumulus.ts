/*
 * Command-Line Interface for the Cumulus API (https://nasa.github.io/cumulus-api/).
 *
 * Requires the following environment variables to be set appropriately:
 *
 * - AWS_PROFILE (or AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY)
 * - AWS_REGION
 * - CUMULUS_PREFIX (value of Terraform `prefix` variable)
 */
import * as FS from 'fs';

import { invokeApi } from '@cumulus/api-client/cumulusApiClient';
import {
  ApiGatewayLambdaProxyPayload,
  HttpMethod,
  InvokeApiFunction,
} from '@cumulus/api-client/types';
import * as Cmd from 'cmd-ts';
import * as Result from 'cmd-ts/dist/cjs/Result';
import { Exit } from 'cmd-ts/dist/cjs/effects';
import fp from 'lodash/fp';

type RequestOptions = {
  readonly prefix: string;
  readonly params?: QueryParams;
  readonly data?: unknown;
};

type RequestFunction = (path: string) => (options: RequestOptions) => Promise<unknown>;

type QueryParams = {
  // This should be readonly, but it's not compatible with
  // ApiGatewayLambdaProxyPayload.queryStringParameters.
  //=> readonly [key: string]: string | readonly string[] | undefined;

  // eslint-disable-next-line functional/prefer-readonly-type
  [key: string]: string | string[] | undefined;
};

type Client = {
  readonly delete: RequestFunction;
  readonly get: RequestFunction;
  readonly post: RequestFunction;
  readonly put: RequestFunction;
};

const clientErrorStatusCodes = Array.from({ length: 100 }, (_, k) => 400 + k);

const VAR_PREFIX = 'CUMULUS_PREFIX';

const CumulusPrefix: Cmd.Type<string, string> = {
  ...Cmd.string,

  description: `Cumulus stack prefix (default: env var ${VAR_PREFIX})`,
  defaultValue: () => {
    const prefix = process.env[VAR_PREFIX];

    if (prefix) return prefix;

    // eslint-disable-next-line functional/no-throw-statement
    throw new Error(
      `Either supply the --prefix option or set the ${VAR_PREFIX} environment variable.`
    );
  },
};

const JSONData: Cmd.Type<string, string> = {
  description: 'Literal JSON value or path to JSON file',
  displayName: 'JSON',

  async from(dataOrPath) {
    // Parse only to validate, returning original string, not parsed value.
    if (Result.isOk(safe(JSON.parse)(dataOrPath))) return dataOrPath;

    // Invalid JSON, so see if it's a file path
    const stats = safe(FS.statSync)(dataOrPath);
    const result = Result.isOk(stats)
      ? stats.value?.isFile()
        ? safe(() => FS.readFileSync(dataOrPath, 'utf8'))()
        : Result.err(new Error('Value is a directory, not a file'))
      : Result.err(new Error('Value is neither a file, nor a valid JSON literal'));

    return Result.isOk(result) ? result.value : Promise.reject(result.error);
  },
};

const globalArgs = {
  prefix: Cmd.option({
    type: CumulusPrefix,
    long: 'prefix',
    short: 'p',
  }),
};

function mkClient(invoke?: InvokeApiFunction) {
  const mkMethod =
    (method: HttpMethod): RequestFunction =>
    (path: string) =>
    ({ prefix, params, data }: RequestOptions) =>
      request({ prefix, method, path, params, data, invoke });

  return {
    delete: mkMethod('DELETE'),
    get: mkMethod('GET'),
    post: mkMethod('POST'),
    put: mkMethod('PUT'),
  };
}

function mkApp(client: Client) {
  return Cmd.binary(
    Cmd.subcommands({
      name: 'cumulus',
      description: 'Cumulus API Command-Line Interface',
      cmds: {
        'async-operations': asyncOperationsCmd(client),
        collections: collectionsCmd(client),
        elasticsearch: elasticsearchCmd(client),
        granules: granulesCmd(client),
        providers: providersCmd(client),
        rules: rulesCmd(client),
      },
    })
  );
}

//------------------------------------------------------------------------------
// COMMAND: async-operations
//------------------------------------------------------------------------------

function asyncOperationsCmd(client: Client) {
  return Cmd.subcommands({
    name: 'async-operations',
    cmds: {
      list: listAsyncOperationsCmd(client),
    },
  });
}

function listAsyncOperationsCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'Lists async operations in the Cumulus system',
    args: { ...globalArgs },
    handler: fp.pipe(client.get('/asyncOperations'), andThen(fp.prop('results'))),
  });
}

//------------------------------------------------------------------------------
// COMMAND: collections
//------------------------------------------------------------------------------

function collectionsCmd(client: Client) {
  return Cmd.subcommands({
    name: 'collections',
    cmds: {
      add: addCollectionCmd(client),
      list: listCollectionsCmd(client),
      replace: replaceCollectionCmd(client),
      delete: deleteCollectionCmd(client),
      upsert: upsertCollectionCmd(client),
    },
  });
}

function addCollectionCmd(client: Client) {
  return Cmd.command({
    name: 'add',
    description: 'Adds a collection',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
      }),
    },
    handler: addCollection(client),
  });
}

function addCollection(client: Client) {
  return (params: { readonly prefix: string; readonly data: string }) =>
    client.post('/collections')(params);
}

function deleteCollectionCmd(client: Client) {
  return Cmd.command({
    name: 'delete',
    description: 'Deletes a collection',
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'Name of the collection to delete',
      }),
      version: Cmd.option({
        type: Cmd.string,
        long: 'version',
        short: 'v',
        description: 'Version of the collection to delete',
      }),
    },
    handler: ({ prefix, name, version }) =>
      client.delete(`/collections/${name}/${version}`)({ prefix }),
  });
}

function replaceCollectionCmd(client: Client) {
  return Cmd.command({
    name: 'replace',
    description: 'Replaces a collection',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of collection definition',
      }),
    },
    handler: replaceCollection(client),
  });
}

function replaceCollection(client: Client) {
  return ({ prefix, data }: { readonly prefix: string; readonly data: string }) => {
    const result = safe(JSON.parse)(data);
    if (Result.isErr(result)) return Promise.reject(result.error);
    const { name, version } = result.value;
    return client.put(`/collections/${name}/${version}`)({ prefix, data });
  };
}

function listCollectionsCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'Lists collections',
    args: {
      ...globalArgs,
      // TODO: Support listing fields to include
      // fields: Cmd.multioption,
    },
    handler: fp.pipe(client.get('/collections'), andThen(fp.prop('results'))),
  });
}

function upsertCollectionCmd(client: Client) {
  return Cmd.command({
    name: 'upsert',
    description: 'Updates (replaces) or inserts (adds) a collection, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of collection definition',
      }),
    },
    handler: upsertCollection(client),
  });
}

function upsertCollection(client: Client) {
  return (params: { readonly prefix: string; readonly data: string }) =>
    replaceCollection(client)(params).catch((error) =>
      error.statusCode === 404 ? addCollection(client)(params) : Promise.reject(error)
    );
}

//------------------------------------------------------------------------------
// COMMAND: elasticsearch
//------------------------------------------------------------------------------

function elasticsearchCmd(client: Client) {
  return Cmd.subcommands({
    name: 'elasticsearch',
    cmds: {
      'change-index': elasticsearchChangeIndexCmd(client),
      'current-index': elasticsearchCurrentIndexCmd(client),
      'index-from-database': elasticsearchIndexFromDatabaseCmd(client),
      'indices-status': elasticsearchIndicesStatusCmd(client),
    },
  });
}

function elasticsearchChangeIndexCmd(client: Client) {
  return Cmd.command({
    name: 'current-index',
    description: 'Changes the current Elasticsearch index',
    args: {
      ...globalArgs,
      currentIndex: Cmd.option({
        type: Cmd.string,
        long: 'current-index',
        description: 'Index to change the alias from',
      }),
      newIndex: Cmd.option({
        type: Cmd.string,
        long: 'new-index',
        description: 'Index to change the alias to',
      }),
      aliasName: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'alias-name',
        description:
          'Alias to use for newIndex.  Will be the default index if not provided.',
      }),
      deleteSource: Cmd.flag({
        long: 'delete-source',
        defaultValue: () => false,
        description: 'Delete the index specified for currentIndex',
      }),
    },
    handler: ({ prefix, ...data }) =>
      client
        .post('/elasticsearch/change-index')({ prefix, data })
        .then(fp.prop('message')),
  });
}

function elasticsearchCurrentIndexCmd(client: Client) {
  return Cmd.command({
    name: 'current-index',
    description:
      'Shows the current aliased index being' +
      ' used by the Cumulus Elasticsearch instance',
    args: { ...globalArgs },
    handler: client.get('/elasticsearch/current-index'),
  });
}

function elasticsearchIndexFromDatabaseCmd(client: Client) {
  return Cmd.command({
    name: 'index-from-database',
    description:
      'Reindexs Elasticsearch from the database.' +
      '  NOTE: After completion, you must run change-index to use the new index.',
    args: {
      ...globalArgs,
      indexName: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'index',
        description: 'Name of an empty index. Defaults to `cumulus-YYYY-MM-DD`.',
      }),
    },
    handler: ({ prefix, ...data }) =>
      client
        .post('/elasticsearch/index-from-database')({ prefix, data })
        .then(fp.prop('message')),
  });
}

function elasticsearchIndicesStatusCmd(client: Client) {
  return Cmd.command({
    name: 'indices-status',
    description: 'Displays information about the Elasticsearch indices',
    args: { ...globalArgs },
    handler: fp.pipe(
      client.get('/elasticsearch/indices-status'),
      andThen(fp.prop('body'))
    ),
  });
}

//------------------------------------------------------------------------------
// COMMAND: granules
//------------------------------------------------------------------------------

function granulesCmd(client: Client) {
  return Cmd.subcommands({
    name: 'granules',
    cmds: {
      'bulk-reingest': granulesBulkReingestCmd(client),
    },
  });
}

function granulesBulkReingestCmd(client: Client) {
  return Cmd.command({
    name: 'bulk-reingest',
    description: 'Reingests the specified granules',
    args: {
      ...globalArgs,
      ids: Cmd.multioption({
        type: Cmd.array(Cmd.string),
        long: 'id',
        description:
          'List of IDs to process.' +
          '  Required if there is no Elasticsearch query provided.',
      }),
      query: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'query',
        short: 'q',
        description:
          'Query to Elasticsearch to determine which Granules to be reingested.' +
          '  Required if no IDs are given.',
      }),
      index: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'index',
        description: 'Elasticsearch index to search with the given query.',
      }),
    },
    handler: ({ prefix, ...params }) =>
      client.post('/granules/bulkReingest')({
        prefix,
        data: {
          ...params,
          query: params.query && {
            query: {
              query_string: {
                query: params.query,
              },
            },
            sort: [{ timestamp: { order: 'desc' } }],
          },
        },
      }),
  });
}

//------------------------------------------------------------------------------
// COMMAND: providers
//------------------------------------------------------------------------------

function providersCmd(client: Client) {
  return Cmd.subcommands({
    name: 'providers',
    cmds: {
      add: addProviderCmd(client),
      list: listProvidersCmd(client),
      replace: replaceProviderCmd(client),
      delete: deleteProviderCmd(client),
      upsert: upsertProviderCmd(client),
    },
  });
}

function addProviderCmd(client: Client) {
  return Cmd.command({
    name: 'add',
    description: 'Adds a provider',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of provider definition',
      }),
    },
    handler: addProvider(client),
  });
}

function addProvider(client: Client) {
  return client.post('/providers');
}

function replaceProviderCmd(client: Client) {
  return Cmd.command({
    name: 'replace',
    description: 'Replaces a provider',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of provider definition',
      }),
    },
    handler: replaceProvider(client),
  });
}

function replaceProvider(client: Client) {
  return ({ prefix, data }: { readonly prefix: string; readonly data: string }) => {
    const result = safe(JSON.parse)(data);

    return Result.isOk(result)
      ? client.put(`/providers/${result.value.id}`)({ prefix, data: result.value })
      : Promise.reject(result.error);
  };
}

function deleteProviderCmd(client: Client) {
  return Cmd.command({
    name: 'delete',
    description: 'Deletes a provider',
    args: {
      ...globalArgs,
      id: Cmd.option({
        type: Cmd.string,
        long: 'id',
        description: 'ID of the provider to delete',
      }),
    },
    handler: ({ prefix, id }) => client.delete(`/providers/${id}`)({ prefix }),
  });
}

function upsertProviderCmd(client: Client) {
  return Cmd.command({
    name: 'upsert',
    description: 'Updates (replaces) or inserts (adds) a provider, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of provider definition',
      }),
    },
    handler: upsertProvider(client),
  });
}

function upsertProvider(client: Client) {
  return (params: { readonly prefix: string; readonly data: string }) =>
    replaceProvider(client)(params).catch((error) =>
      error.statusCode === 404 ? addProvider(client)(params) : Promise.reject(error)
    );
}

function listProvidersCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'Lists providers',
    args: {
      ...globalArgs,
      // TODO: Support listing fields to include
      // fields: Cmd.multioption,
    },
    handler: fp.pipe(client.get('/providers'), andThen(fp.prop('results'))),
  });
}

//------------------------------------------------------------------------------
// COMMAND: rules
//------------------------------------------------------------------------------

type Rule = {
  readonly name: string;
  readonly state: string;
  readonly meta?: {
    readonly rule?: {
      readonly state?: string;
    };
  };
};

function rulesCmd(client: Client) {
  return Cmd.subcommands({
    name: 'rules',
    cmds: {
      add: addRuleCmd(client),
      delete: deleteRuleCmd(client),
      disable: setRuleStateCmd(client, 'DISABLED'),
      enable: setRuleStateCmd(client, 'ENABLED'),
      list: listRulesCmd(client),
      replace: replaceRuleCmd(client),
      run: runRuleCmd(client),
      upsert: upsertRuleCmd(client),
    },
  });
}

function addRuleCmd(client: Client) {
  return Cmd.command({
    name: 'add',
    description: 'Adds a rule',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of rule definition',
      }),
    },
    handler: addRule(client),
  });
}

function addRule(client: Client) {
  return (params: { readonly prefix: string; readonly data: string }) =>
    client.post('/rules')(params);
}

function deleteRuleCmd(client: Client) {
  return Cmd.command({
    name: 'add',
    description: 'Deletes the specified rule',
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'Name of the rule to delete',
      }),
    },
    handler: ({ prefix, name }) => client.delete(`/rules/${name}`)({ prefix }),
  });
}

function setRuleStateCmd(client: Client, state: string) {
  return Cmd.command({
    name: 'add',
    description: `Sets a rule's state to '${state}'`,
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'Name of the rule to change',
      }),
    },
    handler: setRuleState(client, state),
  });
}

function setRuleState(client: Client, state: string) {
  return async ({
    prefix,
    name,
  }: {
    readonly prefix: string;
    readonly name: string;
  }) => {
    const rule = (await client.get(`/rules/${name}`)({ prefix })) as Rule;

    // NOTE: We add a { meta: { rule: { state } } } to the rule definition due to
    // a bug in Cumulus, where a onetime rule ALWAYS triggers its corresponding
    // workflow when the rule is created, even when its "state" is set to
    // "DISABLED".  This additional metadata is used in the DiscoverAndQueueGranules
    // workflow to end execution as soon as it sees there is either no such metadata
    // value, or it is not set to 'ENABLED'.  This additional metadata is necessary
    // because Cumulus does not include the entire rule definition as input to the
    // triggered workflow, but rather only the rule's metadata. This should be
    // removed if and when the Cumulus bug is fixed.
    const meta = {
      ...(rule.meta ?? {}),
      rule: {
        ...(rule.meta?.rule ?? {}),
        state,
      },
    };

    return client.put(`/rules/${rule.name}`)({
      prefix,
      data: { ...rule, state, meta },
    });
  };
}

function replaceRuleCmd(client: Client) {
  return Cmd.command({
    name: 'replace',
    description: 'Replaces a rule',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of rule definition',
      }),
    },
    handler: replaceRule(client),
  });
}

function replaceRule(client: Client) {
  return ({ prefix, data }: { readonly prefix: string; readonly data: string }) => {
    const result = safe(JSON.parse)(data);

    return Result.isOk(result)
      ? client.put(`/rules/${result.value.name}`)({ prefix, data: result.value })
      : Promise.reject(result.error);
  };
}

function upsertRuleCmd(client: Client) {
  return Cmd.command({
    name: 'upsert',
    description: 'Updates (replaces) or inserts (adds) a rule, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'Path to JSON file, or JSON string of rule definition',
      }),
    },
    handler: upsertRule(client),
  });
}

function upsertRule(client: Client) {
  return (params: { readonly prefix: string; readonly data: string }) =>
    replaceRule(client)(params).catch((error) =>
      error.statusCode === 404 ? addRule(client)(params) : Promise.reject(error)
    );
}

function runRuleCmd(client: Client) {
  return Cmd.command({
    name: 'add',
    description: "Runs a 'onetime' rule",
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: "Name of the 'onetime' rule to run",
      }),
    },
    handler: ({ prefix, name }) =>
      client.put(`/rules/${name}`)({ prefix, data: { name, action: 'rerun' } }),
  });
}

function listRulesCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'Lists previously added rules',
    args: {
      ...globalArgs,
      // TODO: Support listing fields to include
      // fields: Cmd.multioption,
    },
    handler: fp.pipe(client.get('/rules'), andThen(fp.prop('results'))),
  });
}

//------------------------------------------------------------------------------
// Helpers
//------------------------------------------------------------------------------

function safe<T extends readonly unknown[], U>(f: (...args: T) => U) {
  // eslint-disable-next-line functional/functional-parameters
  return (...args: T): Result.Result<Error, U> => {
    const value = fp.attempt(() => f(...args));
    return fp.isError(value) ? Result.err(value) : Result.ok(value);
  };
}

function andThen<T, U>(f: (arg: T) => U): (promise: Promise<T>) => Promise<U> {
  return (promise: Promise<T>) => promise.then(f);
}

// function otherwise<T, U>(f: (arg: unknown) => U): (promise: Promise<T>) => Promise<U> {
//   return (promise: Promise<T>) => promise.then(null, f);
// }

function request({
  prefix,
  method,
  path,
  params,
  data,
  invoke = invokeApi,
}: {
  readonly prefix: string;
  readonly method: HttpMethod;
  readonly path: string;
  readonly params?: QueryParams;
  readonly data?: unknown;
  readonly invoke?: InvokeApiFunction;
}) {
  const payload: ApiGatewayLambdaProxyPayload = {
    resource: '/{proxy+}',
    httpMethod: method,
    path,
    queryStringParameters: params,
    headers: { 'Content-Type': 'application/json' },
    body: fp.isUndefined(data) || fp.isString(data) ? data : JSON.stringify(data),
  };

  return invoke({
    prefix,
    payload,
    expectedStatusCodes: [200, ...clientErrorStatusCodes],
    pRetryOptions: {
      onFailedAttempt: fp.pipe(fp.prop('message'), console.error),
    },
  }).then(
    fp.pipe(
      fp.propOr('{}')('body'),
      fp.wrap(JSON.parse),
      fp.attempt,
      fp.cond([
        [fp.isError, (error) => Promise.reject(error)],
        [fp.prop('error'), (body) => Promise.reject(Object.assign(new Error(), body))],
        [fp.stubTrue, fp.identity],
      ])
    )
  );
}

//------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------

const app = mkApp(mkClient());

type RunnerOutput = {
  readonly command: string;
  readonly value: unknown;
};

const isRunnerOutput = (u: unknown): u is RunnerOutput =>
  !fp.isNil(u) && fp.isObject(u) && fp.has('command', u) && fp.has('value', u);

const leaf = (output: unknown): string => {
  if (isRunnerOutput(output)) return leaf(output.value);
  return typeof output === 'string' ? output : JSON.stringify(output, null, 2);
};

const success = (message: string) => new Exit({ exitCode: 0, message, into: 'stdout' });

const failure = (message: string) => new Exit({ exitCode: 1, message, into: 'stderr' });

Cmd.runSafely(app, process.argv)
  .then((result) => (Result.isErr(result) ? result.error : success(leaf(result.value))))
  .catch(({ message }) => failure(`ERROR: ${message}`))
  .then((exit) => exit.run());
