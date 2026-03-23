import { Effect } from "effect";

import { liveActionRuntime, run, type ActionRuntime } from "./core.ts";

export const flakeUpdate = (
  name: string,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    if (name === "all") {
      runtime.console.info("Updating all flake inputs...");
      yield* run(
        [
          "nix",
          "flake",
          "update",
          "--commit-lock-file",
          "--option",
          "commit-lockfile-summary",
          "chore(flake): update lockfile",
        ],
        false,
        runtime,
      );
      runtime.console.ok("Flake update complete");
      return;
    }

    runtime.console.info(`Updating flake input: ${name}...`);
    yield* run(["nix", "flake", "update", name], false, runtime);
    yield* run(["git", "add", "flake.lock"], false, runtime);
    yield* run(["git", "commit", "-m", `chore(flake): update input (${name})`], false, runtime);
    runtime.console.ok("Flake update complete");
  });
