import assert from "node:assert/strict";

import { test } from "bun:test";

import { parseCli, parseCliArgv, renderTopLevelHelp } from "../src/core/cli.ts";

const expectHelp = (argv: readonly string[], needle: RegExp): void => {
  const parsed = parseCliArgv(argv);
  assert.equal(parsed._tag, "Help");
  assert.equal(parsed.exitCode, 0);
  assert.match(parsed.text, needle);
};

const expectError = (
  argv: readonly string[],
  message: string,
  usageNeedle: RegExp,
): void => {
  const parsed = parseCliArgv(argv);
  assert.equal(parsed._tag, "Error");
  assert.equal(parsed.exitCode, 1);
  assert.equal(parsed.message, message);
  assert.match(parsed.text ?? "", usageNeedle);
};

test("parse top-level help when no args are provided", () => {
  const parsed = parseCliArgv(["rice"]);
  assert.equal(parsed._tag, "Help");
  assert.equal(parsed.text, renderTopLevelHelp());
});

test("parse top-level help for explicit help flag", () => {
  expectHelp(["rice", "--help"], /Usage: rice <COMMAND>/);
  expectHelp(["--help"], /Usage: rice <COMMAND>/);
});

test("parse accepts argv without the binary prefix", () => {
  const cli = parseCli(["system", "build"]);
  assert.deepEqual(cli, {
    command: {
      _tag: "System",
      command: "Build",
    },
  });
});

test("parse home build keeps default host when only user is provided", () => {
  const cli = parseCli(["rice", "home", "build", "alice"]);
  assert.equal(cli.command._tag, "Home");
  assert.equal(cli.command.command._tag, "Build");
  assert.equal(cli.command.command.user, "alice");
  assert.equal(cli.command.command.host, "wsl");
});

test("parse home switch uses defaults when user and host are omitted", () => {
  const cli = parseCli(["rice", "home", "switch"]);
  assert.equal(cli.command._tag, "Home");
  assert.equal(cli.command.command._tag, "Switch");
  assert.equal(cli.command.command.user, "annt");
  assert.equal(cli.command.command.host, "wsl");
});

test("parse home command treats trailing help flag as group help", () => {
  expectHelp(["rice", "home", "build", "--help"], /Usage: rice home <COMMAND> \[USER\] \[HOST\]/);
});

for (const [name, argv, usage] of [
  ["system group help on missing subcommand", ["rice", "system"], /Usage: rice system <COMMAND>/],
  ["home group help on help flag", ["rice", "home", "--help"], /Usage: rice home <COMMAND> \[USER\] \[HOST\]/],
  ["nixos group help on missing subcommand", ["rice", "nixos"], /Usage: rice nixos <COMMAND>/],
  ["darwin group help on help flag", ["rice", "darwin", "--help"], /Usage: rice darwin <COMMAND>/],
  ["nix group help on missing subcommand", ["rice", "nix"], /Usage: rice nix <COMMAND>/],
  ["flake group help on help flag", ["rice", "flake", "--help"], /Usage: rice flake <COMMAND>/],
] as const) {
  test(name, () => {
    expectHelp(argv, usage);
  });
}

for (const [name, argv, message, usage] of [
  ["unknown top-level command errors", ["rice", "wat"], "unknown command: wat", /Usage: rice <COMMAND>/],
  ["unknown system subcommand errors", ["rice", "system", "wat"], "unknown system subcommand: wat", /Usage: rice system <COMMAND>/],
  ["unknown home subcommand errors", ["rice", "home", "wat"], "unknown home subcommand: wat", /Usage: rice home <COMMAND> \[USER\] \[HOST\]/],
  ["unknown nixos subcommand errors", ["rice", "nixos", "wat"], "unknown nixos subcommand: wat", /Usage: rice nixos <COMMAND>/],
  ["unknown darwin subcommand errors", ["rice", "darwin", "wat"], "unknown darwin subcommand: wat", /Usage: rice darwin <COMMAND>/],
  ["unknown nix subcommand errors", ["rice", "nix", "wat"], "unknown nix subcommand: wat", /Usage: rice nix <COMMAND>/],
  ["unknown flake subcommand errors", ["rice", "flake", "wat"], "unknown flake subcommand: wat", /Usage: rice flake <COMMAND>/],
] as const) {
  test(name, () => {
    expectError(argv, message, usage);
  });
}

for (const [name, argv, message, usage] of [
  ["system build rejects extra args", ["rice", "system", "build", "extra"], "unexpected arguments: extra", /Usage: rice system <COMMAND>/],
  ["home build rejects too many args", ["rice", "home", "build", "a", "b", "c"], "unexpected arguments: c", /Usage: rice home <COMMAND> \[USER\] \[HOST\]/],
  ["nixos build rejects extra args", ["rice", "nixos", "build", "extra"], "unexpected arguments: extra", /Usage: rice nixos <COMMAND>/],
  ["darwin switch rejects extra args", ["rice", "darwin", "switch", "extra"], "unexpected arguments: extra", /Usage: rice darwin <COMMAND>/],
  ["nix clean rejects extra args", ["rice", "nix", "clean", "extra"], "unexpected arguments: extra", /Usage: rice nix <COMMAND>/],
  ["flake check rejects extra args", ["rice", "flake", "check", "extra"], "unexpected arguments: extra", /Usage: rice flake <COMMAND>/],
  ["flake update rejects extra args", ["rice", "flake", "update", "fenix", "extra"], "unexpected arguments: extra", /Usage: rice flake <COMMAND>/],
] as const) {
  test(name, () => {
    const parsed = parseCliArgv(argv);
    assert.equal(parsed._tag, "Error");
    assert.equal(parsed.message, message);
    assert.match(parsed.text ?? "", usage);
  });
}

test("flake update requires an input name", () => {
  expectError(
    ["rice", "flake", "update"],
    'missing flake input name for "update"',
    /Usage: rice flake <COMMAND>/,
  );
});

test("flake update treats help flag as a missing input name", () => {
  expectError(
    ["rice", "flake", "update", "--help"],
    'missing flake input name for "update"',
    /Usage: rice flake <COMMAND>/,
  );
});

test("parseCli throws on help result", () => {
  assert.throws(() => parseCli(["rice"]), new Error("expected parsed CLI"));
});

test("parseCli throws with the parser error message", () => {
  assert.throws(() => parseCli(["rice", "wat"]), new Error("unknown command: wat"));
});
