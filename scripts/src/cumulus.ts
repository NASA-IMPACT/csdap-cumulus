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
import dateformat from 'dateformat';
import fp from 'lodash/fp';

import { asyncUnfold } from './unfold';

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

const NO_RETRY_STATUS_CODES = [
  200,
  201,
  202,
  204,
  ...Array.from({ length: 100 }, (_, k) => 400 + k), // 400-499
];
const VAR_PREFIX = 'CUMULUS_PREFIX';

const CumulusPrefix: Cmd.Type<string, string> = {
  ...Cmd.string,

  description: `Cumulus stack prefix${
    process.env[VAR_PREFIX]
      ? ''
      : ` (alternative: set environment variable ${VAR_PREFIX})`
  }`,
  defaultValue: process.env[VAR_PREFIX]
    ? () => process.env[VAR_PREFIX] || ''
    : undefined,
  defaultValueIsSerializable: Boolean(process.env[VAR_PREFIX]),
};

const JSONData: Cmd.Type<string, string> = {
  description: 'literal JSON value or path to JSON file',
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

const QueryStringParameter: Cmd.Type<string, readonly [string, string]> = {
  description: 'query string parameter',
  displayName: 'NAME=VALUE',

  async from(param) {
    const [name, value, ...rest] = param.split('=');

    return value === undefined || rest.length
      ? Promise.reject(new Error('Option must be of the form NAME=VALUE'))
      : [name, value];
  },
};

const globalArgs = {
  prefix: Cmd.option({
    type: CumulusPrefix,
    long: 'prefix',
  }),
};

const listArgs = {
  ...globalArgs,
  all: Cmd.flag({
    long: 'all',
    description: 'list ALL records, regardless of --limit',
  }),
  limit: Cmd.option({
    type: Cmd.number,
    long: 'limit',
    description: 'number of records to return',
    defaultValue: () => 10,
    defaultValueIsSerializable: true,
  }),
  page: Cmd.option({
    type: Cmd.number,
    long: 'page',
    description: 'page number (1-based)',
    defaultValue: () => 1,
    defaultValueIsSerializable: true,
  }),
  sort_by: Cmd.option({
    type: Cmd.string,
    long: 'sort-by',
    description: 'name of field to sort records by',
    defaultValue: () => 'timestamp',
    defaultValueIsSerializable: true,
  }),
  order: Cmd.option({
    type: Cmd.oneOf(['asc', 'desc']),
    long: 'order',
    description: 'name of field to sort records by',
    defaultValue: (): 'asc' | 'desc' => 'asc',
    defaultValueIsSerializable: true,
  }),
  params: Cmd.multioption({
    type: Cmd.array(QueryStringParameter),
    long: 'param',
    short: '?',
    description: 'query string parameter (may be specified multiple times)',
  }),
  fields: Cmd.option({
    type: Cmd.optional(Cmd.string),
    long: 'fields',
    description:
      'comma-separated list of field names to return in each record' +
      ' (if not specified, all fields are returned)',
  }),
};

function responseErrorMessage(response: unknown) {
  const reasons = fp.map(
    fp.prop('reason'),
    fp.pathOr([], ['meta', 'body', 'error', 'root_cause'], response)
  );

  return reasons.join(' | ') || JSON.stringify(response);
}

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
        executions: executionsCmd(client),
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
      get: getAsyncOperationCmd(client),
      list: listAsyncOperationsCmd(client),
    },
  });
}

function getAsyncOperationCmd(client: Client) {
  return Cmd.command({
    name: 'get',
    description: 'Get information about an async operation',
    args: {
      ...globalArgs,
      id: Cmd.option({
        type: Cmd.string,
        long: 'id',
        description: 'ID of an async operation',
      }),
    },
    handler: ({ prefix, id }) => client.get(`/asyncOperations/${id}`)({ prefix }),
  });
}

function listAsyncOperationsCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'List async operations',
    args: {
      ...globalArgs,
      params: listArgs.params,
    },
    handler: fp.pipe(
      ({ params, ...rest }) => ({ ...rest, params: Object.fromEntries(params) }),
      client.get('/asyncOperations'),
      andThen(fp.prop('results'))
    ),
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
    description: 'Add a collection',
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
    description: 'Delete a collection',
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'name of the collection to delete',
      }),
      version: Cmd.option({
        type: Cmd.string,
        long: 'version',
        short: 'v',
        description: 'version of the collection to delete',
      }),
    },
    handler: ({ prefix, name, version }) =>
      client.delete(`/collections/${name}/${version}`)({ prefix }),
  });
}

function replaceCollectionCmd(client: Client) {
  return Cmd.command({
    name: 'replace',
    description: 'Replace a collection',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of collection definition',
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
    description: 'List collections',
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
    description: 'Update (replace) a collection, or insert (add) it, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of collection definition',
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
    description: 'Change current Elasticsearch index',
    args: {
      ...globalArgs,
      currentIndex: Cmd.option({
        type: Cmd.string,
        long: 'current-index',
        description: 'index to change the alias from',
      }),
      newIndex: Cmd.option({
        type: Cmd.string,
        long: 'new-index',
        description: 'index to change the alias to',
      }),
      aliasName: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'alias-name',
        description: 'alias to use for --new-index (default index if not provided)',
      }),
      deleteSource: Cmd.flag({
        long: 'delete-source',
        defaultValue: () => false,
        description: 'delete the index specified for --current-index',
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
      'shows the current aliased index being' +
      ' used by the Cumulus Elasticsearch instance',
    args: { ...globalArgs },
    handler: client.get('/elasticsearch/current-index'),
  });
}

function elasticsearchIndexFromDatabaseCmd(client: Client) {
  return Cmd.command({
    name: 'index-from-database',
    description:
      'Re-index Elasticsearch from the database' +
      ' (NOTE: after completion, you must run change-index to use the new index)',
    args: {
      ...globalArgs,
      indexName: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'index',
        description: 'name of an empty index',
        defaultValue: () => `cumulus-${dateformat(Date.now(), 'yyyy-mm-dd')}`,
        defaultValueIsSerializable: true,
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
    description: 'Display information about Elasticsearch indices',
    args: { ...globalArgs },
    handler: fp.pipe(
      client.get('/elasticsearch/indices-status'),
      andThen(fp.prop('body'))
    ),
  });
}

//------------------------------------------------------------------------------
// COMMAND: executions
//------------------------------------------------------------------------------

function executionsCmd(client: Client) {
  return Cmd.subcommands({
    name: 'executions',
    cmds: {
      'find-by-list': findExecutionsByGranulesListCmd(client),
      // 'find-by-query': findExecutionsByESQuery(client),
      list: listExecutionsCmd(client),
    },
  });
}

// TODO Support many granules (currently only a single granule is supported)
function findExecutionsByGranulesListCmd(client: Client) {
  return Cmd.command({
    name: 'find-by-list',
    description: 'Find executions associated with specified list of granules',
    args: {
      ...globalArgs,
      collectionId: Cmd.option({
        type: Cmd.string,
        long: 'collection-id',
        description: "ID of the granule's collection",
      }),
      granuleId: Cmd.option({
        type: Cmd.string,
        long: 'granule-id',
        description: 'ID of the granule',
      }),
    },
    handler: ({ prefix }) =>
      client.get('/executions/search-by-granules')({
        prefix,
      }),
  });
}

function listExecutionsCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'List executions',
    args: {
      ...globalArgs,
    },
    handler: fp.pipe(client.get('/executions'), andThen(fp.prop('results'))),
  });
}

//------------------------------------------------------------------------------
// COMMAND: granules
//------------------------------------------------------------------------------

function granulesCmd(client: Client) {
  return Cmd.subcommands({
    name: 'granules',
    cmds: {
      'bulk-delete': granulesBulkDeleteCmd(client),
      'bulk-reingest': granulesBulkReingestCmd(client),
      count: granulesCountCmd(client),
      delete: granulesDeleteCmd(client),
      get: granulesGetCmd(client),
      list: granulesListCmd(client),
      unpublish: granulesUnpublishCmd(client),
    },
  });
}

function granulesUnpublishCmd(client: Client) {
  return Cmd.command({
    name: 'unpublish',
    description: 'Unpublish a granule from the CMR',
    args: {
      ...globalArgs,
      id: Cmd.option({
        type: Cmd.string,
        long: 'id',
        description: 'ID of the granule to unpublish',
      }),
    },
    handler: ({ prefix, id }) =>
      client.put(`/granules/${id}`)({ prefix, data: { action: 'removeFromCmr' } }),
  });
}

function granulesDeleteCmd(client: Client) {
  return Cmd.command({
    name: 'delete',
    description: 'Delete a granule (must first be unpublished)',
    args: {
      ...globalArgs,
      id: Cmd.option({
        type: Cmd.string,
        long: 'id',
        description: 'ID of the granule to delete',
      }),
    },
    handler: ({ prefix, id }) => client.delete(`/granules/${id}`)({ prefix }),
  });
}

function granulesGetCmd(client: Client) {
  return Cmd.command({
    name: 'get',
    description: 'Get details about a granule',
    args: {
      ...globalArgs,
      id: Cmd.option({
        type: Cmd.string,
        long: 'id',
        description: 'ID of the granule to fetch',
      }),
    },
    handler: ({ prefix, id }) => client.get(`/granules/${id}`)({ prefix }),
  });
}

function granulesCountCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'Count granules',
    args: {
      ...globalArgs,
      // TODO support listArgs
    },
    handler: fp.pipe(client.get('/granules'), andThen(fp.path('meta.count'))),
  });
}

function listGranules(client: Client) {
  return async ({
    prefix,
    all = false,
    limit = 10,
    page = 1,
    params = [],
    ...listParams
  }: {
    readonly prefix: string;
    readonly all?: boolean;
    readonly limit?: number;
    readonly page?: number;
    readonly params?: readonly (readonly [string, string])[];
    readonly [key: string]: unknown;
  }) => {
    async function getPage(page: number) {
      const response = await client.get('/granules')({
        prefix,
        params: {
          limit: all ? '100' : `${limit}`,
          page: `${page}`,
          ...Object.fromEntries(params),
          ...listParams,
        },
      });
      const results = fp.prop('results', response);

      return Array.isArray(results)
        ? results.length > 0 && { output: results, input: page + 1 }
        : Promise.reject(new Error(responseErrorMessage(response)));
    }

    const granules = [];

    // eslint-disable-next-line functional/no-loop-statement
    for await (const items of asyncUnfold(getPage)(page)) {
      // eslint-disable-next-line functional/immutable-data
      granules.push(...items);
      if (!all && granules.length >= limit) break;
    }

    return all || granules.length <= limit ? granules : granules.slice(0, limit);
  };
}

function granulesListCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'List granules',
    args: listArgs,
    handler: listGranules(client),
  });
}

function granulesBulkDeleteCmd(client: Client) {
  return Cmd.command({
    name: 'bulk-delete',
    description: 'Delete specified granules',
    args: {
      ...globalArgs,
      dryRun: Cmd.flag({
        long: 'dry-run',
        description:
          'perform a dry run, counting all granules that would otherwise be deleted',
      }),
      all: listArgs.all,
      limit: listArgs.limit,
      params: listArgs.params,
      query: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'query',
        short: 'q',
        description:
          'query to Elasticsearch to determine which Granules to be deleted' +
          ' (required if no IDs are given)',
      }),
      index: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'index',
        description: 'Elasticsearch index to search with the given query',
      }),
    },
    handler: async ({ prefix, dryRun, all, limit, params, query, index }) => {
      const deleteBatch =
        (ids: readonly unknown[]) =>
        async (start: number, end = start + 2000) => {
          const idsSlice = ids.slice(start, end);
          const bulkDeleteParams = { prefix, data: { ids: idsSlice } };
          const bulkDelete = client.post('/granules/bulkDelete');

          return (
            start < ids.length && {
              output: await bulkDelete(bulkDeleteParams),
              input: end,
            }
          );
        };

      if (query) {
        return client.post('/granules/bulkDelete')({
          prefix,
          data: { index, query: { query_string: { query } } },
        });
      }

      const granules = await listGranules(client)({ prefix, all, limit, params });
      const ids = fp.map(fp.prop('granuleId'), granules);

      if (dryRun) return `[dryrun] Would delete ${granules.length} granules`;

      // eslint-disable-next-line functional/no-loop-statement
      for await (const response of asyncUnfold(deleteBatch(ids))(0))
        console.log(response);

      return `Bulk deleting ${granules.length} granules`;
    },
  });
}

function granulesBulkReingestCmd(client: Client) {
  return Cmd.command({
    name: 'bulk-reingest',
    description: 'Re-ingest specified granules',
    args: {
      ...globalArgs,
      ids: Cmd.multioption({
        type: Cmd.array(Cmd.string),
        long: 'id',
        description:
          'list of IDs to process' +
          ' (required if there is no Elasticsearch query provided)',
      }),
      query: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'query',
        short: 'q',
        description:
          'query to Elasticsearch to determine which Granules to be re-ingested' +
          ' (required if no IDs are given)',
      }),
      index: Cmd.option({
        type: Cmd.optional(Cmd.string),
        long: 'index',
        description: 'Elasticsearch index to search with the given query',
      }),
    },
    handler: ({ prefix, ids, query, index }) =>
      client.post('/granules/bulkReingest')({
        prefix,
        data: {
          ids: ids.length === 0 ? undefined : ids,
          index,
          query: query && {
            query: {
              query_string: {
                query,
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
    description: 'Add a provider',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of provider definition',
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
    description: 'Replace a provider',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of provider definition',
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
    description: 'Delete a provider',
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
    description: 'Update (replace) a provider, or insert (add) it, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of provider definition',
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
    description: 'List providers',
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
    description: 'Add a rule',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of rule definition',
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
    description: 'Delete a rule',
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'name of the rule to delete',
      }),
    },
    handler: ({ prefix, name }) => client.delete(`/rules/${name}`)({ prefix }),
  });
}

function setRuleStateCmd(client: Client, state: string) {
  return Cmd.command({
    name: 'add',
    description: `Set a rule's state to '${state}'`,
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: 'name of the rule to change',
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
    description: 'Replace a rule',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of rule definition',
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
    description: 'Update (replace) a rule, or insert (add) it, if not found',
    args: {
      ...globalArgs,
      data: Cmd.option({
        type: JSONData,
        long: 'data',
        short: 'd',
        description: 'path to JSON file, or JSON string of rule definition',
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
    description: "Run a 'onetime' rule",
    args: {
      ...globalArgs,
      name: Cmd.option({
        type: Cmd.string,
        long: 'name',
        short: 'n',
        description: "name of the 'onetime' rule to run",
      }),
    },
    handler: ({ prefix, name }) =>
      client.put(`/rules/${name}`)({ prefix, data: { name, action: 'rerun' } }),
  });
}

function listRulesCmd(client: Client) {
  return Cmd.command({
    name: 'list',
    description: 'List rules',
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
  const invokeParams = {
    prefix,
    payload,
    expectedStatusCodes: NO_RETRY_STATUS_CODES,
    pRetryOptions: {
      onFailedAttempt: fp.pipe(fp.prop('message'), console.error),
    },
  };

  // TODO Add --verbose option
  // console.log(payload);

  return invoke(invokeParams).then(
    fp.pipe(
      fp.propOr('{}')('body'),
      fp.wrap(JSON.parse),
      fp.attempt,
      // TODO Add --verbose option
      // fp.tap(console.log),
      fp.cond([
        [fp.isError, (error) => Promise.reject(error)],
        [
          fp.overEvery([fp.prop('error'), fp.prop('message')]),
          ({ message }) => Promise.reject(new Error(message)),
        ],
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
