import * as crypto from 'crypto';
import * as fs from 'fs';
import * as path from 'path';

import * as Cmd from 'cmd-ts';
import * as Result from 'cmd-ts/dist/cjs/Result';
import { Directory } from 'cmd-ts/dist/cjs/batteries/fs';
import { Exit } from 'cmd-ts/dist/cjs/effects';
import * as fp from 'lodash/fp';

type Info = {
  readonly Name: string;
  readonly Checksum: {
    readonly Value: string;
    readonly Algorithm: string;
  };
};

type Ummg = {
  readonly DataGranule: {
    readonly ArchiveAndDistributionInformation: readonly Info[];
  };
};

type Granule = {
  readonly ummg: Ummg;
  readonly ummgPath: string;
  readonly infoPaths: readonly string[];
};

const isTagged = (u: unknown): u is { readonly _tag: string } =>
  fp.isObject(u) && '_tag' in u;

const isOk = (u: unknown): u is Result.Ok<unknown> =>
  isTagged(u) && u._tag === 'ok' && 'value' in u;

const isErr = (u: unknown): u is Result.Err<unknown> =>
  isTagged(u) && u._tag === 'error' && 'error' in u;

const isResult = (u: unknown): u is Result.Result<unknown, unknown> =>
  isOk(u) || isErr(u);

const flattenResult = (
  result: Result.Result<unknown, unknown>
): Result.Result<unknown, unknown> =>
  isOk(result) && isResult(result.value) ? flattenResult(result.value) : result;

const mapResult =
  <T, U>(fn: (value: T) => U) =>
  <E>(result: Result.Result<E, T>): Result.Result<E, U> =>
    isErr(result) ? result : Result.ok(fn(result.value));

const findGranules: (
  dir: string
) => Result.Result<readonly string[], readonly Granule[]> = fp.pipe(
  readdirSyncRec,
  fp.filter((filepath) => path.basename(filepath) !== '.DS_Store'),
  fp.groupBy(path.dirname),
  fp.toPairs,
  fp.map(([dir, filePaths]) => makeGranule(dir, filePaths)),
  (results: readonly Result.Result<string, Granule>[]) =>
    results.some(Result.isErr)
      ? Result.err(results.filter(Result.isErr).map((r) => r.error))
      : Result.ok(results.filter(Result.isOk).map((r) => r.value))
);

function makeGranule(
  dir: string,
  filePaths: readonly string[]
): Result.Result<string, Granule> {
  const [ummgPaths, infoPaths] = fp.partition(fp.endsWith('cmr.json'), filePaths);
  const ummgNames = ummgPaths.map(fp.unary(path.basename));

  switch (ummgPaths.length) {
    case 0:
      return Result.err(`No cmr.json file in ${dir}/`);
    case 1: {
      const toGranule = mapResult((ummg: Ummg) => ({
        ummg,
        ummgPath: ummgPaths[0],
        infoPaths,
      }));
      return toGranule(readUmmgSync(ummgPaths[0]));
    }
    default:
      return Result.err(`Multiple cmr.json files in ${dir}/: ${ummgNames.join(', ')}`);
  }
}

function syncGranule(granule: Granule): string | undefined {
  const { ummg, ummgPath } = granule;
  const dir = path.dirname(ummgPath);
  const infos = ummg.DataGranule.ArchiveAndDistributionInformation.filter(
    fp.prop('Checksum')
  );
  const infosP = infos.map((info) => syncInfo(path.join(dir, info.Name), info));
  const ummgP = fp.set('DataGranule.ArchiveAndDistributionInformation', infosP, ummg);

  // If the UMM-G metadata changed (due to one or more updated infos), rewrite it.
  if (fp.isEqual(ummgP, ummg)) return undefined;
  fs.writeFileSync(ummgPath, JSON.stringify(ummgP, null, 2));
  return ummgPath;
}

function syncInfo(infoPath: string, info: Info) {
  // If a file exists, assume its metadata is correct and return immediately.
  if (fs.existsSync(infoPath)) return info;

  // The file at `infoPath` does not exist, so we need to create it.
  // We're just creating a dummy text file, as Cumulus doesn't care about the
  // specific contents of any file, other than the `*cmr.json` file, which we
  // don't pass into this function.

  const algorithm = info.Checksum.Algorithm;
  const hash = crypto.createHash(algorithm.replace('-', ''));
  const contents = 'Hello Cumulus!\n';
  const checksum = hash.update(contents).digest('hex');

  fs.writeFileSync(infoPath, contents, 'utf-8');

  return {
    ...info,
    SizeInBytes: Buffer.byteLength(contents, 'utf-8'),
    Checksum: {
      Algorithm: algorithm,
      Value: checksum,
    },
  };
}

function readdirSyncRec(dir: string): readonly string[] {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((dirent) => {
    const fullName = path.join(dir, dirent.name);
    return dirent.isFile() ? [fullName] : readdirSyncRec(fullName);
  });
}

function readUmmgSync(cmrJsonPath: string): Result.Result<string, Ummg> {
  try {
    return Result.ok(JSON.parse(fs.readFileSync(cmrJsonPath, 'utf-8')));
  } catch (e) {
    return Result.err(String(e));
  }
}

const app = Cmd.binary(
  Cmd.command({
    name: 'generate-test-granule-files',
    description: 'Generates dummy granule files for smoke tests.',
    handler: fp.pipe(
      fp.prop('dir'),
      findGranules,
      mapResult(fp.map(syncGranule)),
      mapResult(fp.filter(Boolean))
    ),
    args: {
      dir: Cmd.option({
        short: 'd',
        long: 'dir',
        type: Directory,
        description: 'Parent directory of granule files for all collections.',
        defaultValue: () => 'app/stacks/cumulus/resources/granules',
        defaultValueIsSerializable: true,
      }),
    },
  })
);

const stringify = (u: unknown) =>
  typeof u === 'object' ? JSON.stringify(u, null, 2) : `${u}`;

const success = (message: string) => new Exit({ exitCode: 0, message, into: 'stdout' });

const failure = (message: string) => new Exit({ exitCode: 1, message, into: 'stderr' });

const toExit: (result: Result.Result<Exit, unknown>) => Exit = fp.pipe(
  flattenResult,
  fp.cond([
    [Result.isErr, fp.pipe(fp.prop('error'), stringify, failure)],
    [Result.isOk, fp.pipe(fp.prop('value'), stringify, success)],
  ])
);

Cmd.runSafely(app, process.argv)
  .then(toExit)
  .catch(({ message }) => failure(`ERROR: ${message}`))
  .then((exit) => exit.run());
