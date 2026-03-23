import { mkdtempSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

import { Effect } from "effect";

import type { ActionRuntime } from "../src/core/actions/core.ts";
import { parseCli, type Cli } from "../src/core/cli.ts";
import { runCliWithContext } from "../src/core/index.ts";
import type { Platform } from "../src/core/tasks/index.ts";
import { silentConsole } from "../src/runtime/console.ts";

export const parseCliForTest = (args: readonly string[]): Cli => parseCli(args);

export const cmd = (parts: readonly string[]): string[] => [...parts];

export interface CaptureResult {
  readonly error?: Error;
  readonly commands: readonly string[][];
}

const settle = async (
  effect: Effect.Effect<void, Error>,
): Promise<Error | undefined> => {
  const result = await Effect.runPromise(Effect.either(effect));
  return result._tag === "Left" ? result.left : undefined;
};

const mockRuntime = (
  run: (command: readonly string[]) => Effect.Effect<void, Error>,
): ActionRuntime => ({
  console: silentConsole,
  process: { run },
});

export const captureCommands = async (
  action: (runtime: ActionRuntime) => Effect.Effect<void, Error>,
): Promise<CaptureResult> => {
  const commands: string[][] = [];
  const runtime = mockRuntime((command) =>
    Effect.sync(() => {
      commands.push([...command]);
    }),
  );

  const error = await settle(action(runtime));
  return { error, commands };
};

export const captureCommandsWithFailure = async (
  action: (runtime: ActionRuntime) => Effect.Effect<void, Error>,
  failAt: number,
): Promise<CaptureResult> => {
  const commands: string[][] = [];
  let calls = 0;
  const runtime = mockRuntime((command) =>
    Effect.try({
      try: () => {
        commands.push([...command]);
        calls += 1;
        if (calls === failAt) {
          throw new Error(`mock failure at call ${failAt}`);
        }
      },
      catch: (error) => (error instanceof Error ? error : new Error(String(error))),
    }),
  );

  const error = await settle(action(runtime));
  return { error, commands };
};

export const runCliCapture = async (
  args: readonly string[],
  host: string,
  current: Platform,
): Promise<CaptureResult> => {
  const cli = parseCliForTest(args);
  return captureCommands((runtime) => runCliWithContext(cli, host, current, runtime));
};

export const tempPath = (prefix: string): string => mkdtempSync(join(tmpdir(), `${prefix}-`));
