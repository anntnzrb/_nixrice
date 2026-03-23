export interface Cli {
  readonly command: Command;
}

export type Command =
  | { readonly _tag: "System"; readonly command: SystemCommand }
  | { readonly _tag: "Home"; readonly command: HomeCommand }
  | { readonly _tag: "Nixos"; readonly command: NixosCommand }
  | { readonly _tag: "Darwin"; readonly command: DarwinCommand }
  | { readonly _tag: "Nix"; readonly command: NixCommand }
  | { readonly _tag: "Flake"; readonly command: FlakeCommand };

export type SystemCommand = "Build" | "Switch";

export type HomeCommand =
  | { readonly _tag: "Build"; readonly user: string; readonly host: string }
  | { readonly _tag: "Switch"; readonly user: string; readonly host: string };

export type NixosCommand = "Build" | "Boot" | "Switch";
export type DarwinCommand = "Build" | "Switch";
export type NixCommand = "Optimise" | "Repair" | "Clean";

export type FlakeCommand =
  | { readonly _tag: "Check" }
  | { readonly _tag: "Fmt" }
  | { readonly _tag: "Update"; readonly name: string };

export type ParseResult =
  | { readonly _tag: "Success"; readonly cli: Cli }
  | { readonly _tag: "Help"; readonly text: string; readonly exitCode: number }
  | {
      readonly _tag: "Error";
      readonly message: string;
      readonly text?: string;
      readonly exitCode: number;
    };

const HELP_FLAGS = new Set(["-h", "--help"]);

const topLevelHelp = `NixOS/Darwin configuration management

Usage: rice <COMMAND>

Commands:
  system  System configuration
  home    Home Manager
  nixos   NixOS commands
  darwin  Darwin commands
  nix     Nix maintenance
  flake   Flake management

Options:
  -h, --help  Print help`;

const groupHelp = {
  system: `System configuration

Usage: rice system <COMMAND>

Commands:
  build   Build system configuration
  switch  Build and switch immediately

Options:
  -h, --help  Print help`,
  home: `Home Manager

Usage: rice home <COMMAND> [USER] [HOST]

Commands:
  build   Build home-manager configuration
  switch  Build and activate home-manager configuration

Options:
  -h, --help  Print help`,
  nixos: `NixOS commands

Usage: rice nixos <COMMAND>

Commands:
  build   Build NixOS configuration
  boot    Build and activate on next boot
  switch  Build and switch immediately

Options:
  -h, --help  Print help`,
  darwin: `Darwin commands

Usage: rice darwin <COMMAND>

Commands:
  build   Build Darwin configuration
  switch  Build and switch immediately

Options:
  -h, --help  Print help`,
  nix: `Nix maintenance

Usage: rice nix <COMMAND>

Commands:
  optimise  Optimize nix store
  repair    Repair nix store
  clean     Clean nix cache and run cleanup

Options:
  -h, --help  Print help`,
  flake: `Flake management

Usage: rice flake <COMMAND>

Commands:
  check   Check flake validity
  fmt     Format and check code
  update  Update flake inputs (use "all" to update all)

Options:
  -h, --help  Print help`,
} as const;

const isHelp = (value: string | undefined): boolean => value !== undefined && HELP_FLAGS.has(value);

const error = (message: string, text?: string): ParseResult => ({
  _tag: "Error",
  message,
  text,
  exitCode: 1,
});

const success = (cli: Cli): ParseResult => ({ _tag: "Success", cli });

const help = (text: string, exitCode = 0): ParseResult => ({
  _tag: "Help",
  text,
  exitCode,
});

const parseNoArgs = <T>(
  args: readonly string[],
  value: T,
  usage: string,
): ParseResult => {
  if (args.length > 0) {
    return error(`unexpected arguments: ${args.join(" ")}`, usage);
  }
  return success({ command: value } as Cli);
};

const parseHome = (args: readonly string[]): ParseResult => {
  const [subcommand, ...rest] = args;

  if (subcommand === undefined || isHelp(subcommand)) {
    return help(groupHelp.home);
  }

  if (subcommand !== "build" && subcommand !== "switch") {
    return error(`unknown home subcommand: ${subcommand}`, groupHelp.home);
  }

  if (rest.some((part) => isHelp(part))) {
    return help(groupHelp.home);
  }

  if (rest.length > 2) {
    return error(`unexpected arguments: ${rest.slice(2).join(" ")}`, groupHelp.home);
  }

  const user = rest[0] ?? "annt";
  const host = rest[1] ?? "wsl";
  return success({
    command: {
      _tag: "Home",
      command:
        subcommand === "build"
          ? { _tag: "Build", user, host }
          : { _tag: "Switch", user, host },
    },
  });
};

const parseFlake = (args: readonly string[]): ParseResult => {
  const [subcommand, ...rest] = args;

  if (subcommand === undefined || isHelp(subcommand)) {
    return help(groupHelp.flake);
  }

  switch (subcommand) {
    case "check":
      return parseNoArgs(rest, { _tag: "Flake", command: { _tag: "Check" } }, groupHelp.flake);
    case "fmt":
      return parseNoArgs(rest, { _tag: "Flake", command: { _tag: "Fmt" } }, groupHelp.flake);
    case "update": {
      if (rest.length === 0 || isHelp(rest[0])) {
        return error('missing flake input name for "update"', groupHelp.flake);
      }
      if (rest.length > 1) {
        return error(`unexpected arguments: ${rest.slice(1).join(" ")}`, groupHelp.flake);
      }
      const name = rest[0]!;
      return success({
        command: {
          _tag: "Flake",
          command: { _tag: "Update", name },
        },
      });
    }
    default:
      return error(`unknown flake subcommand: ${subcommand}`, groupHelp.flake);
  }
};

export const parseCliArgv = (argv: readonly string[]): ParseResult => {
  const args = argv[0] === "rice" ? argv.slice(1) : argv;
  const [command, ...rest] = args;

  if (command === undefined || isHelp(command)) {
    return help(topLevelHelp);
  }

  switch (command) {
    case "system": {
      const [subcommand, ...tail] = rest;
      if (subcommand === undefined || isHelp(subcommand)) {
        return help(groupHelp.system);
      }
      switch (subcommand) {
        case "build":
          return parseNoArgs(tail, { _tag: "System", command: "Build" }, groupHelp.system);
        case "switch":
          return parseNoArgs(tail, { _tag: "System", command: "Switch" }, groupHelp.system);
        default:
          return error(`unknown system subcommand: ${subcommand}`, groupHelp.system);
      }
    }
    case "home":
      return parseHome(rest);
    case "nixos": {
      const [subcommand, ...tail] = rest;
      if (subcommand === undefined || isHelp(subcommand)) {
        return help(groupHelp.nixos);
      }
      switch (subcommand) {
        case "build":
          return parseNoArgs(tail, { _tag: "Nixos", command: "Build" }, groupHelp.nixos);
        case "boot":
          return parseNoArgs(tail, { _tag: "Nixos", command: "Boot" }, groupHelp.nixos);
        case "switch":
          return parseNoArgs(tail, { _tag: "Nixos", command: "Switch" }, groupHelp.nixos);
        default:
          return error(`unknown nixos subcommand: ${subcommand}`, groupHelp.nixos);
      }
    }
    case "darwin": {
      const [subcommand, ...tail] = rest;
      if (subcommand === undefined || isHelp(subcommand)) {
        return help(groupHelp.darwin);
      }
      switch (subcommand) {
        case "build":
          return parseNoArgs(tail, { _tag: "Darwin", command: "Build" }, groupHelp.darwin);
        case "switch":
          return parseNoArgs(tail, { _tag: "Darwin", command: "Switch" }, groupHelp.darwin);
        default:
          return error(`unknown darwin subcommand: ${subcommand}`, groupHelp.darwin);
      }
    }
    case "nix": {
      const [subcommand, ...tail] = rest;
      if (subcommand === undefined || isHelp(subcommand)) {
        return help(groupHelp.nix);
      }
      switch (subcommand) {
        case "optimise":
          return parseNoArgs(tail, { _tag: "Nix", command: "Optimise" }, groupHelp.nix);
        case "repair":
          return parseNoArgs(tail, { _tag: "Nix", command: "Repair" }, groupHelp.nix);
        case "clean":
          return parseNoArgs(tail, { _tag: "Nix", command: "Clean" }, groupHelp.nix);
        default:
          return error(`unknown nix subcommand: ${subcommand}`, groupHelp.nix);
      }
    }
    case "flake":
      return parseFlake(rest);
    default:
      return error(`unknown command: ${command}`, topLevelHelp);
  }
};

export const parseCli = (argv: readonly string[]): Cli => {
  const parsed = parseCliArgv(argv);
  if (parsed._tag !== "Success") {
    throw new Error(parsed._tag === "Error" ? parsed.message : "expected parsed CLI");
  }
  return parsed.cli;
};

export const renderTopLevelHelp = (): string => topLevelHelp;
