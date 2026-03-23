import { Effect } from "effect";

import { liveActionRuntime, run, type ActionRuntime } from "./core.ts";

export const homeBuild = (
  user: string,
  host: string,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    runtime.console.info(`Building home-manager for ${user}@${host}...`);
    yield* run(
      ["nix", "build", `.#homeConfigurations.${user}@${host}.activationPackage`],
      false,
      runtime,
    );
    runtime.console.ok("Home-manager build complete");
  });

export const homeSwitch = (
  user: string,
  host: string,
  runtime: ActionRuntime = liveActionRuntime,
): Effect.Effect<void, Error> =>
  Effect.gen(function* () {
    yield* homeBuild(user, host, runtime);
    runtime.console.info("Activating home-manager...");
    yield* run(["./result/activate"], false, runtime);
    runtime.console.ok("Home-manager switch complete");
  });
