import assert from "node:assert/strict";

import { test } from "bun:test";

import { runCli, runCliWithContext } from "../src/core/index.ts";
import {
  captureCommands,
  captureCommandsWithFailure,
  cmd,
  parseCliForTest,
  runCliCapture,
} from "./support.ts";

test("system build linux routes to nixos build", async () => {
  const { error, commands } = await runCliCapture(["rice", "system", "build"], "zadar", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nixos-rebuild", "build", "--flake", ".#"])]);
});

test("system build darwin routes to darwin build", async () => {
  const { error, commands } = await runCliCapture(["rice", "system", "build"], "beirut", "darwin");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nix", "build", ".#darwinConfigurations.beirut.system"])]);
});

test("system switch linux runs two steps", async () => {
  const { error, commands } = await runCliCapture(["rice", "system", "switch"], "zadar", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["nixos-rebuild", "build", "--flake", ".#"]),
    cmd(["nixos-rebuild", "switch", "--sudo", "--flake", ".#"]),
  ]);
});

test("system switch darwin runs two steps", async () => {
  const { error, commands } = await runCliCapture(["rice", "system", "switch"], "beirut", "darwin");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["nix", "build", ".#darwinConfigurations.beirut.system"]),
    cmd(["sudo", "./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#beirut"]),
  ]);
});

test("darwin build rejects linux platform", async () => {
  const { error, commands } = await runCliCapture(["rice", "darwin", "build"], "zadar", "linux");
  assert.ok(error instanceof Error);
  assert.equal(error?.message, "Requires macOS");
  assert.deepEqual(commands, []);
});

test("nixos build routes to build command", async () => {
  const { error, commands } = await runCliCapture(["rice", "nixos", "build"], "zadar", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nixos-rebuild", "build", "--flake", ".#"])]);
});

test("nixos build rejects darwin platform", async () => {
  const { error, commands } = await runCliCapture(["rice", "nixos", "build"], "beirut", "darwin");
  assert.ok(error instanceof Error);
  assert.equal(error?.message, "Requires Linux");
  assert.deepEqual(commands, []);
});

test("nixos boot routes to boot command", async () => {
  const { error, commands } = await runCliCapture(["rice", "nixos", "boot"], "zadar", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nixos-rebuild", "boot", "--sudo", "--flake", ".#"])]);
});

test("nixos switch routes to switch command", async () => {
  const { error, commands } = await runCliCapture(["rice", "nixos", "switch"], "zadar", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nixos-rebuild", "switch", "--sudo", "--flake", ".#"])]);
});

test("darwin switch routes to switch command", async () => {
  const { error, commands } = await runCliCapture(["rice", "darwin", "switch"], "beirut", "darwin");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["sudo", "./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#beirut"]),
  ]);
});

test("home build runs single step", async () => {
  const { error, commands } = await runCliCapture(
    ["rice", "home", "build", "alice", "mbp"],
    "ignored",
    "linux",
  );
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["nix", "build", ".#homeConfigurations.alice@mbp.activationPackage"]),
  ]);
});

test("home switch runs build then activate", async () => {
  const { error, commands } = await runCliCapture(
    ["rice", "home", "switch", "alice", "mbp"],
    "ignored",
    "linux",
  );
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["nix", "build", ".#homeConfigurations.alice@mbp.activationPackage"]),
    cmd(["./result/activate"]),
  ]);
});

test("nix optimise uses sudo", async () => {
  const { error, commands } = await runCliCapture(["rice", "nix", "optimise"], "ignored", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["sudo", "nix", "store", "optimise"])]);
});

test("nix repair uses sudo", async () => {
  const { error, commands } = await runCliCapture(["rice", "nix", "repair"], "ignored", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["sudo", "nix-store", "--verify", "--check-contents", "--repair"]),
  ]);
});

test("nix clean route runs cleanup commands", async () => {
  const { error, commands } = await runCliCapture(["rice", "nix", "clean"], "ignored", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nh", "clean", "all"]), cmd(["nh", "clean", "user"])]);
});

test("flake fmt runs pre-commit", async () => {
  const { error, commands } = await runCliCapture(["rice", "flake", "fmt"], "ignored", "linux");
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["pre-commit", "run", "--all-files"])]);
});

test("flake update all runs commit lockfile flow", async () => {
  const { error, commands } = await runCliCapture(
    ["rice", "flake", "update", "all"],
    "ignored",
    "linux",
  );
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd([
      "nix",
      "flake",
      "update",
      "--commit-lock-file",
      "--option",
      "commit-lockfile-summary",
      "chore(flake): update lockfile",
    ]),
  ]);
});

test("flake update single input runs git flow", async () => {
  const { error, commands } = await runCliCapture(
    ["rice", "flake", "update", "fenix"],
    "ignored",
    "linux",
  );
  assert.equal(error, undefined);
  assert.deepEqual(commands, [
    cmd(["nix", "flake", "update", "fenix"]),
    cmd(["git", "add", "flake.lock"]),
    cmd(["git", "commit", "-m", "chore(flake): update input (fenix)"]),
  ]);
});

test("run cli wrapper executes commands", async () => {
  const cli = parseCliForTest(["rice", "flake", "check"]);
  const { error, commands } = await captureCommands((runtime) => runCli(cli, runtime));
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["nix", "flake", "check", "."])]);
});

test("run cli system build propagates exec error", async () => {
  const cli = parseCliForTest(["rice", "system", "build"]);
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => runCliWithContext(cli, "zadar", "linux", runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nixos-rebuild", "build", "--flake", ".#"])]);
});

test("system switch propagates second-step failure", async () => {
  const cli = parseCliForTest(["rice", "system", "switch"]);
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => runCliWithContext(cli, "zadar", "linux", runtime),
    2,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [
    cmd(["nixos-rebuild", "build", "--flake", ".#"]),
    cmd(["nixos-rebuild", "switch", "--sudo", "--flake", ".#"]),
  ]);
});

test("darwin system switch stops when the build step fails", async () => {
  const cli = parseCliForTest(["rice", "system", "switch"]);
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => runCliWithContext(cli, "beirut", "darwin", runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nix", "build", ".#darwinConfigurations.beirut.system"])]);
});

test("darwin system switch propagates switch-step failure", async () => {
  const cli = parseCliForTest(["rice", "system", "switch"]);
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => runCliWithContext(cli, "beirut", "darwin", runtime),
    2,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [
    cmd(["nix", "build", ".#darwinConfigurations.beirut.system"]),
    cmd(["sudo", "./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#beirut"]),
  ]);
});
