import { Effect } from "effect";

import * as actions from "./actions/index.ts";
import {
  parseCliArgv,
  type Cli,
  type DarwinCommand,
  type FlakeCommand,
  type HomeCommand,
  type NixCommand,
  type NixosCommand,
  type SystemCommand,
} from "./cli.ts";
import {
  DARWIN_BUILD,
  DARWIN_SWITCH,
  FLAKE_CHECK,
  FLAKE_FMT,
  NIX_OPTIMISE,
  NIX_REPAIR,
  NIXOS_BOOT,
  NIXOS_BUILD,
  NIXOS_SWITCH,
  type Platform,
} from "./tasks/index.ts";

const runSystem = (
  command: SystemCommand,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  switch (command) {
    case "Build":
      return actions.execTask(current === "darwin" ? DARWIN_BUILD : NIXOS_BUILD, host, current, runtime);
    case "Switch":
      return Effect.gen(function* () {
        if (current === "darwin") {
          yield* actions.execTask(DARWIN_BUILD, host, current, runtime);
          yield* actions.execTask(DARWIN_SWITCH, host, current, runtime);
          return;
        }

        yield* actions.execTask(NIXOS_BUILD, host, current, runtime);
        yield* actions.execTask(NIXOS_SWITCH, host, current, runtime);
      });
  }
};

const runHome = (
  command: HomeCommand,
  host: string,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  const targetHost = command.host ?? host;

  switch (command._tag) {
    case "Build":
      return actions.homeBuild(command.user, targetHost, runtime);
    case "Switch":
      return actions.homeSwitch(command.user, targetHost, runtime);
  }
};

const runNixos = (
  command: NixosCommand,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  switch (command) {
    case "Build":
      return actions.execTask(NIXOS_BUILD, host, current, runtime);
    case "Boot":
      return actions.execTask(NIXOS_BOOT, host, current, runtime);
    case "Switch":
      return actions.execTask(NIXOS_SWITCH, host, current, runtime);
  }
};

const runDarwin = (
  command: DarwinCommand,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  switch (command) {
    case "Build":
      return actions.execTask(DARWIN_BUILD, host, current, runtime);
    case "Switch":
      return actions.execTask(DARWIN_SWITCH, host, current, runtime);
  }
};

const runNix = (
  command: NixCommand,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  switch (command) {
    case "Optimise":
      return actions.execTask(NIX_OPTIMISE, host, current, runtime);
    case "Repair":
      return actions.execTask(NIX_REPAIR, host, current, runtime);
    case "Clean":
      return actions.nixClean(runtime);
  }
};

const runFlake = (
  command: FlakeCommand,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime,
): Effect.Effect<void, Error> => {
  switch (command._tag) {
    case "Check":
      return actions.execTask(FLAKE_CHECK, host, current, runtime);
    case "Fmt":
      return actions.execTask(FLAKE_FMT, host, current, runtime);
    case "Update":
      return actions.flakeUpdate(command.name, runtime);
  }
};

export const runCli = (
  cli: Cli,
  runtime: actions.ActionRuntime = actions.liveActionRuntime,
): Effect.Effect<void, Error> => {
  const host = actions.hostShortname();
  const current = actions.currentPlatform();
  return runCliWithContext(cli, host, current, runtime);
};

export const runCliWithContext = (
  cli: Cli,
  host: string,
  current: Platform,
  runtime: actions.ActionRuntime = actions.liveActionRuntime,
): Effect.Effect<void, Error> => {
  switch (cli.command._tag) {
    case "System":
      return runSystem(cli.command.command, host, current, runtime);
    case "Home":
      return runHome(cli.command.command, host, runtime);
    case "Nixos":
      return runNixos(cli.command.command, host, current, runtime);
    case "Darwin":
      return runDarwin(cli.command.command, host, current, runtime);
    case "Nix":
      return runNix(cli.command.command, host, current, runtime);
    case "Flake":
      return runFlake(cli.command.command, host, current, runtime);
  }
};

export const main = (
  argv: readonly string[] = ["rice", ...process.argv.slice(2)],
): Effect.Effect<number> =>
  Effect.gen(function* () {
    const parsed = parseCliArgv(argv);

    switch (parsed._tag) {
      case "Help":
        yield* Effect.sync(() => {
          console.log(parsed.text);
        });
        return parsed.exitCode;
      case "Error":
        yield* Effect.sync(() => {
          actions.liveActionRuntime.console.err(parsed.message);
          if (parsed.text) {
            console.error("");
            console.error(parsed.text);
          }
        });
        return parsed.exitCode;
      case "Success": {
        const result = yield* Effect.either(runCli(parsed.cli, actions.liveActionRuntime));
        if (result._tag === "Left") {
          yield* Effect.sync(() => {
            actions.liveActionRuntime.console.err(result.left.message);
          });
          return 1;
        }
        return 0;
      }
    }
  });
