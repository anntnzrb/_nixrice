import assert from "node:assert/strict";

import { test } from "bun:test";

import {
  currentPlatform,
  hostShortname,
  withContext,
} from "../src/core/actions/index.ts";
import { DARWIN_BUILD } from "../src/core/tasks/index.ts";
import { parseCliForTest } from "./support.ts";

test("parse home build defaults", () => {
  const cli = parseCliForTest(["rice", "home", "build"]);
  assert.equal(cli.command._tag, "Home");
  assert.equal(cli.command.command._tag, "Build");
  assert.equal(cli.command.command.user, "annt");
  assert.equal(cli.command.command.host, undefined);
});

test("parse home switch overrides defaults", () => {
  const cli = parseCliForTest(["rice", "home", "switch", "alice", "mbp"]);
  assert.equal(cli.command._tag, "Home");
  assert.equal(cli.command.command._tag, "Switch");
  assert.equal(cli.command.command.user, "alice");
  assert.equal(cli.command.command.host, "mbp");
});

test("parse flake update all", () => {
  const cli = parseCliForTest(["rice", "flake", "update", "all"]);
  assert.equal(cli.command._tag, "Flake");
  assert.equal(cli.command.command._tag, "Update");
  assert.equal(cli.command.command.name, "all");
});

test("task context substitution works", () => {
  const command = DARWIN_BUILD.cmd.map((part) => withContext(part, "beirut"));
  assert.equal(command[2], ".#darwinConfigurations.beirut.system");
});

test("current platform matches target cfg", () => {
  const expected = process.platform === "darwin" ? "darwin" : "linux";
  assert.equal(currentPlatform(), expected);
});

test("host shortname has no domain suffix", () => {
  const host = hostShortname();
  assert.notEqual(host.length, 0);
  assert.equal(host.includes("."), false);
});
