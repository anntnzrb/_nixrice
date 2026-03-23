import assert from "node:assert/strict";
import { existsSync, mkdirSync, rmSync } from "node:fs";
import { join } from "node:path";

import { test } from "bun:test";
import { Effect } from "effect";

import {
  err,
  flakeUpdate,
  homeBuild,
  homeSwitch,
  nixClean,
  nixCleanWithHome,
  requirePlatform,
  run,
} from "../src/core/actions/index.ts";
import { silentConsole } from "../src/runtime/console.ts";
import { liveProcessRunner } from "../src/runtime/process.ts";
import { captureCommands, captureCommandsWithFailure, cmd, tempPath } from "./support.ts";

test("platform requirement allows match", () => {
  assert.doesNotThrow(() => requirePlatform("linux", "linux"));
});

test("platform requirement errors on mismatch", () => {
  assert.throws(() => requirePlatform("linux", "darwin"), new Error("Requires Linux"));
});

test("run prepends sudo when requested", async () => {
  const { error, commands } = await captureCommands((runtime) => run(cmd(["echo", "ok"]), true, runtime));
  assert.equal(error, undefined);
  assert.deepEqual(commands, [cmd(["sudo", "echo", "ok"])]);
});

test("run reports non zero exit", async () => {
  const error = await Effect.runPromise(
    Effect.either(run(["sh", "-c", "exit 7"], false, { console: silentConsole, process: liveProcessRunner })),
  );
  assert.equal(error._tag, "Left");
  assert.match(error.left.message, /exit: 7/);
});

test("run reports zero exit", async () => {
  await Effect.runPromise(
    run(["sh", "-c", "exit 0"], false, { console: silentConsole, process: liveProcessRunner }),
  );
});

test("err logger is callable", () => {
  const original = console.error;
  console.error = () => {};
  try {
    err("synthetic error");
  } finally {
    console.error = original;
  }
});

test("nix clean removes cache and runs cleanup", async () => {
  const home = tempPath("rice-home");
  const cacheDir = join(home, ".cache/nix");
  mkdirSync(cacheDir, { recursive: true });

  const { error, commands } = await captureCommands((runtime) => nixCleanWithHome(home, runtime));
  assert.equal(error, undefined);
  assert.equal(existsSync(cacheDir), false);
  assert.deepEqual(commands, [cmd(["nh", "clean", "all"]), cmd(["nh", "clean", "user"])]);

  rmSync(home, { recursive: true, force: true });
});

test("nix clean reads HOME from the environment in the public wrapper", async () => {
  const home = tempPath("rice-home-env");
  const cacheDir = join(home, ".cache/nix");
  const originalHome = process.env.HOME;
  mkdirSync(cacheDir, { recursive: true });
  process.env.HOME = home;

  try {
    const { error, commands } = await captureCommands((runtime) => nixClean(runtime));
    assert.equal(error, undefined);
    assert.equal(existsSync(cacheDir), false);
    assert.deepEqual(commands, [cmd(["nh", "clean", "all"]), cmd(["nh", "clean", "user"])]);
  } finally {
    if (originalHome === undefined) {
      delete process.env.HOME;
    } else {
      process.env.HOME = originalHome;
    }
    rmSync(home, { recursive: true, force: true });
  }
});

test("home build propagates run error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => homeBuild("alice", "mbp", runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.equal(commands.length, 1);
});

test("home switch propagates activate-step failure", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => homeSwitch("alice", "mbp", runtime),
    2,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [
    cmd(["nix", "build", ".#homeConfigurations.alice@mbp.activationPackage"]),
    cmd(["./result/activate"]),
  ]);
});

test("nix clean propagates first cleanup error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => nixCleanWithHome(undefined, runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nh", "clean", "all"])]);
});

test("nix clean propagates second cleanup error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => nixCleanWithHome(undefined, runtime),
    2,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nh", "clean", "all"]), cmd(["nh", "clean", "user"])]);
});

test("flake update all propagates run error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => flakeUpdate("all", runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.equal(commands.length, 1);
});

test("flake update single propagates update error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => flakeUpdate("fenix", runtime),
    1,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nix", "flake", "update", "fenix"])]);
});

test("flake update single propagates git add error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => flakeUpdate("fenix", runtime),
    2,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [cmd(["nix", "flake", "update", "fenix"]), cmd(["git", "add", "flake.lock"])]);
});

test("flake update single propagates git commit error", async () => {
  const { error, commands } = await captureCommandsWithFailure(
    (runtime) => flakeUpdate("fenix", runtime),
    3,
  );
  assert.ok(error instanceof Error);
  assert.deepEqual(commands, [
    cmd(["nix", "flake", "update", "fenix"]),
    cmd(["git", "add", "flake.lock"]),
    cmd(["git", "commit", "-m", "chore(flake): update input (fenix)"]),
  ]);
});
