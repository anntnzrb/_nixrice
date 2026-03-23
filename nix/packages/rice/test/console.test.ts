import assert from "node:assert/strict";

import { test } from "bun:test";

import { err, info, ok, preview, silentConsole } from "../src/runtime/console.ts";

const captureConsole = <T>(action: () => T): { readonly result: T; readonly logs: readonly string[]; readonly errors: readonly string[] } => {
  const logs: string[] = [];
  const errors: string[] = [];
  const originalLog = console.log;
  const originalError = console.error;

  console.log = (...args: unknown[]) => {
    logs.push(args.map(String).join(" "));
  };
  console.error = (...args: unknown[]) => {
    errors.push(args.map(String).join(" "));
  };

  try {
    return {
      result: action(),
      logs,
      errors,
    };
  } finally {
    console.log = originalLog;
    console.error = originalError;
  }
};

test("ok prints a green success line", () => {
  const { logs, errors } = captureConsole(() => ok("done"));
  assert.equal(errors.length, 0);
  assert.equal(logs.length, 1);
  assert.match(logs[0] ?? "", /✓/);
  assert.match(logs[0] ?? "", /done/);
});

test("err prints a red error line", () => {
  const { logs, errors } = captureConsole(() => err("boom"));
  assert.equal(logs.length, 0);
  assert.equal(errors.length, 1);
  assert.match(errors[0] ?? "", /✗/);
  assert.match(errors[0] ?? "", /boom/);
});

test("info prints a blue info line", () => {
  const { logs, errors } = captureConsole(() => info("heads up"));
  assert.equal(errors.length, 0);
  assert.equal(logs.length, 1);
  assert.match(logs[0] ?? "", /→/);
  assert.match(logs[0] ?? "", /heads up/);
});

test("preview prints the rendered command line", () => {
  const { logs, errors } = captureConsole(() => preview(["nix", "flake", "check", "."]));
  assert.equal(errors.length, 0);
  assert.equal(logs.length, 1);
  assert.match(logs[0] ?? "", /\$ nix flake check \./);
});

test("silent console suppresses all output", () => {
  const { logs, errors } = captureConsole(() => {
    silentConsole.ok("done");
    silentConsole.err("boom");
    silentConsole.info("heads up");
    silentConsole.preview(["echo", "ok"]);
  });
  assert.deepEqual(logs, []);
  assert.deepEqual(errors, []);
});
