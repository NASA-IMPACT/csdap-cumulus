/*
 * Quick and dirty hack to generate terraform import commands from Terraform
 * error messages about resources that already exist.
 *
 * Usage:
 *
 *   yarn terraform-doctor < log/up/MODULE.log
 *   cd $(terraspace info MODULE --path)
 *   PRESCRIPTION
 *   cd /work
 *
 * where:
 *
 *   - MODULE is one of: cumulus, data-persistence, rds-cluster
 *   - PRESCRIPTION is the list of commands output by terraform-doctor.  After
 *     changing directory to the corresponding module path, run every command
 *     output by terraform-doctor before changing directory back to `/work`.
 *
 * Running all of the prescribed commands should fix all of the
 * "duplicate resource" errors.
 */

import readline from 'readline';

const fixerFactories = [
  function mkCloudformationStackFixer(
    err: string
  ): ((addr: string) => string) | undefined {
    const errRE = /Error: .+ CloudFormation Stack .+ \[(?<id>[^\s]+)\] already exists/;
    const { id } = err.match(errRE)?.groups ?? {};
    const fix = (id: string) => (addr: string) => `terraform import ${addr} ${id}`;

    return id ? fix(id) : undefined;
  },
  function mkDynamoDbTableFixer(err: string): ((addr: string) => string) | undefined {
    const errRE = /Error: .+ DynamoDB Table .+ already exists: (?<name>[^\s]+)/;
    const { name } = err.match(errRE)?.groups ?? {};
    const fix = (name: string) => (addr: string) => `terraform import ${addr} ${name}`;

    return name ? fix(name) : undefined;
  },
  function mkLambdaEventSourceMappingFixer(
    err: string
  ): ((addr: string) => string) | undefined {
    const errRE = /Error: .+ Lambda Event Source Mapping .+ UUID (?<uuid>[^\s]+)/;
    const { uuid } = err.match(errRE)?.groups ?? {};
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const fix = (uuid: string) => (_addr: string) =>
      `aws lambda delete-event-source-mapping --uuid ${uuid}`;

    return uuid ? fix(uuid) : undefined;
  },
  function mkLambdaFunctionFixer(err: string): ((addr: string) => string) | undefined {
    // Error message includes `exist`, not `exists`, but matching either case for forward
    // compatibility, in case spelling error is fixed in future version of Terraform.
    const errRE = /Error: .+ Function already exists?: (?<name>[^\s]+)/;
    const { name } = err.match(errRE)?.groups ?? {};
    const fix = (name: string) => (addr: string) => `terraform import ${addr} ${name}`;

    return name ? fix(name) : undefined;
  },
  function mkSecurityGroupFixer(err: string): ((addr: string) => string) | undefined {
    const errRE = /Error: .+ security group '(?<name>[^\s]+)' already exists/;
    const { name } = err.match(errRE)?.groups ?? {};
    const fix = (name: string) => (addr: string) =>
      `terraform import ${addr} $(aws ec2 describe-security-groups` +
      ' --query SecurityGroups[].GroupId' +
      ' --output text' +
      ` --filter Name=group-name,Values=${name})`;

    return name ? fix(name) : undefined;
  },
  function mkFallbackFixer(err: string): ((addr: string) => string) | undefined {
    const errRE = /Error: .+ (?<id>[^\s]+) already exists[.]/;
    const { id } = err.match(errRE)?.groups ?? {};
    const fix = (id: string) => (addr: string) => `terraform import ${addr} ${id}`;

    return id ? fix(id) : undefined;
  },
];

function mkAddress({
  path,
  type,
  name,
}: {
  readonly path: string | undefined;
  readonly type: string | undefined;
  readonly name: string | undefined;
}): string {
  // .terraform/modules/cumulus/tf-modules/archive/granule_files_cache_updater.tf
  const { dir } =
    path?.match(/(?:[.]terraform[/](?<dir>.+)[/])?(?:[^/]+[.]tf)/)?.groups ?? {};

  if (!dir) return `${type}.${name}`;

  const [, module, ...rest] = dir.split('/');
  const suffix =
    rest.length === 0
      ? ''
      : rest.length === 1
      ? `.${rest[0]}`
      : rest[0] === 'tf-modules' && rest[1] === module
      ? ''
      : `.module.${rest[1]}`;

  return `module.${module}${suffix}.${type}.${name}`.replace('-', '_');
}

async function readLines(): Promise<readonly string[]> {
  // eslint-disable-next-line functional/prefer-readonly-type
  const lines: string[] = [];
  const rl = readline.createInterface({ input: process.stdin });

  // If lines are from Terraspace "up" log file, ignore all lines through latest
  // "Releasing lock state" line so that we process only lines related to last run of
  // "terraspace all up", thus avoiding older errors that may no longer apply.

  // eslint-disable-next-line functional/no-loop-statement
  for await (const line of rl) {
    if (line.match(/Releasing state lock/i)) {
      // eslint-disable-next-line functional/immutable-data
      lines.length = 0;
    } else {
      // eslint-disable-next-line functional/immutable-data
      lines.push(line);
    }
  }

  return lines;
}

async function main() {
  const lines = await readLines();
  // eslint-disable-next-line functional/no-let
  let fixer;

  // eslint-disable-next-line functional/no-loop-statement
  for (const line of lines) {
    const locMatch = line.match(
      / {2}on (?<path>[^\s]+) .+ in resource "(?<type>[^\s]+)" "(?<name>[^\s]+)"/
    );

    if (!fixer && !locMatch) {
      fixer = fixerFactories.map((factory) => factory(line)).find(Boolean);
    } else if (fixer && locMatch) {
      const { path, type, name } = locMatch.groups || {};
      const addr = mkAddress({ path, type, name });

      console.log(fixer(addr));

      fixer = undefined;
    }
  }
}

main();
