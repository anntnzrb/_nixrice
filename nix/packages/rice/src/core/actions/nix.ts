import { rmSync } from "node:fs";
import path from "node:path";

import { Effect } from "effect";

import { liveActionRuntime, run, type ActionRuntime } from "./core.ts";

const removeCacheDir = (home: string | undefined): void => {
  if (!home) {
    return;
  }

  try {
    rmSync(path.join(home, ".cache/nix"), {
      force: true,
      recursive: true,
    });
  } catch {
    // ignore cleanup failures for parity with the Rust implementation
  }
};

export const nixClean = (
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> => nixCleanWithHome(process.env.HOME, runtime);

export const nixCleanWithHome = (
  home: string | undefined,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    runtime.console.info("Cleaning nix cache...");
    yield* Effect.sync(() => removeCacheDir(home));
    yield* run(["nh", "clean", "all"], false, runtime);
    yield* run(["nh", "clean", "user"], false, runtime);
    runtime.console.ok("Nix cleanup complete");
  });
