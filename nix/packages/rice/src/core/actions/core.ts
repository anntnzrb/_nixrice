import os from "node:os";

import { Effect } from "effect";

import { liveConsole, type RiceConsole } from "../../runtime/console.ts";
import { liveProcessRunner, type ProcessRunner } from "../../runtime/process.ts";
import type { Platform, Task } from "../tasks/index.ts";

export interface ActionRuntime {
  readonly console: RiceConsole;
  readonly process: ProcessRunner;
}

export const liveActionRuntime: ActionRuntime = {
  console: liveConsole,
  process: liveProcessRunner,
};

const HOST_TOKEN = "{host}";

const toError = (error: unknown): Error => {
  if (error instanceof Error) {
    return error;
  }
  return new Error(String(error));
};

export const currentPlatform = (): Platform =>
  process.platform === "darwin" ? "darwin" : "linux";

export const hostShortname = (): string => {
  const hostname = os.hostname() || "unknown";
  return hostname.split(".")[0] || "unknown";
};

export const withContext = (template: string, host: string): string =>
  template.replaceAll(HOST_TOKEN, host);

export const requirePlatform = (required: Platform, current: Platform): void => {
  if (required === current) {
    return;
  }

  throw new Error(required === "darwin" ? "Requires macOS" : "Requires Linux");
};

export const run = (
  command: readonly string[],
  sudo: boolean,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    const line = sudo ? ["sudo", ...command] : [...command];
    runtime.console.preview(line);
    yield* runtime.process.run(line);
  });

export const execTask = (
  task: Task,
  host: string,
  current: Platform,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    const requiredPlatform = task.platform;
    if (requiredPlatform !== undefined) {
      yield* Effect.try({
        try: () => requirePlatform(requiredPlatform, current),
        catch: toError,
      });
    }

    runtime.console.info(withContext(task.info, host));

    const command = task.cmd.map((part) => withContext(part, host));
    yield* run(command, task.sudo, runtime);
    runtime.console.ok(task.ok);
  });
