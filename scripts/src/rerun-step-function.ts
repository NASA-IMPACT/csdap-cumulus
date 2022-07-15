import * as sfn from '@aws-sdk/client-sfn';
import * as sts from '@aws-sdk/client-sts';
import * as Cmd from 'cmd-ts';
import * as Result from 'cmd-ts/dist/cjs/Result';
import { Exit } from 'cmd-ts/dist/cjs/effects';
import * as fp from 'lodash/fp';
import * as uuid from 'uuid';

const stateMachineOption = Cmd.option({
  type: Cmd.string,
  long: 'machine',
  description: 'name (including prefix) of the state machine to rerun',
});

const executionOption = Cmd.option({
  type: Cmd.string,
  long: 'execution',
  description: 'name/UUID4 of execution from which to obtain input for new execution',
});

const app = Cmd.binary(
  Cmd.command({
    name: 'rerun-step-function',
    description:
      'Rerun an AWS State Machine with the same input from an earlier execution',
    handler: rerun,
    args: {
      machineName: stateMachineOption,
      executionName: executionOption,
    },
  })
);

async function getAccount(): Promise<string> {
  return new sts.STS({})
    .getCallerIdentity({})
    .then(({ Account: account = 'UNKNOWN' }) => account);
}

async function describeExecution({
  account,
  machineName,
  executionName,
}: {
  readonly account: string;
  readonly machineName: string;
  readonly executionName: string;
}): Promise<sfn.DescribeExecutionCommandOutput> {
  return new sfn.SFN({}).describeExecution({
    executionArn:
      `arn:aws:states:us-west-2:${account}:` +
      `execution:${machineName}:${executionName}`,
  });
}

async function startExecution({
  account,
  machineName,
  executionName,
  input,
}: {
  readonly account: string;
  readonly machineName: string;
  readonly executionName: string;
  readonly input: string;
}): Promise<sfn.StartExecutionCommandOutput> {
  return new sfn.SFN({}).startExecution({
    stateMachineArn: `arn:aws:states:us-west-2:${account}:stateMachine:${machineName}`,
    name: executionName,
    input,
  });
}

async function rerun({
  machineName,
  executionName,
}: {
  readonly [key: string]: string;
}) {
  const account = await getAccount();
  const output = await describeExecution({ account, machineName, executionName });
  const newExecutionName = uuid.v4();
  const input = JSON.stringify(
    fp.set(
      ['cumulus_meta', 'execution_name'],
      newExecutionName,
      JSON.parse(output.input ?? '{}')
    )
  );

  return startExecution({
    account,
    machineName,
    executionName: newExecutionName,
    input,
  });
}

const success = (message: unknown) =>
  new Exit({
    exitCode: 0,
    message:
      typeof message === 'object' ? JSON.stringify(message, null, 2) : `${message}`,
    into: 'stdout',
  });

const failure = (message: string) => new Exit({ exitCode: 1, message, into: 'stderr' });

Cmd.runSafely(app, process.argv)
  .then(async (result) =>
    Result.isErr(result) ? result.error : success(await result.value)
  )
  .catch(({ message }) => failure(`ERROR: ${message}`))
  .then((exit) => exit.run());
