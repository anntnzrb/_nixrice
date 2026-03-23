import { spawn } from "node:child_process";

import { Effect } from "effect";

export interface ProcessRunner {
  readonly run: (command: readonly string[]) => Effect.Effect<void, Error>;
}

const exitCode = (code: number | null, signal: NodeJS.Signals | null): number => {
  if (typeof code === "number") {
    return code;
  }
  if (signal) {
    return -1;
  }
  return 1;
};

const toError = (error: unknown): Error => {
  if (error instanceof Error) {
    return error;
  }
  return new Error(String(error));
};

const commandFailure = (
  command: readonly string[],
  code: number | null,
  signal: NodeJS.Signals | null,
): Error => new Error(`command failed: ${command.join(" ")} (exit: ${exitCode(code, signal)})`);

const spawnCommand = async (command: readonly string[]): Promise<void> => {
  await new Promise<void>((resolve, reject) => {
    const child = spawn(command[0]!, command.slice(1), {
      stdio: "inherit",
    });

    child.once("error", (error) => {
      reject(toError(error));
    });

    child.once("close", (code, signal) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(commandFailure(command, code, signal));
    });
  });
};

export const liveProcessRunner: ProcessRunner = {
  run: (command) =>
    Effect.tryPromise({
      try: () => spawnCommand(command),
      catch: toError,
    }),
};
