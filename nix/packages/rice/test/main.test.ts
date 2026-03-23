import assert from "node:assert/strict";

import { test } from "bun:test";
import { Effect } from "effect";

import { liveActionRuntime } from "../src/core/actions/index.ts";
import { main } from "../src/core/index.ts";
import type { RiceConsole } from "../src/runtime/console.ts";
import type { ProcessRunner } from "../src/runtime/process.ts";

const captureConsole = async <T>(
  action: () => Promise<T> | T,
): Promise<{ readonly result: T; readonly logs: readonly string[]; readonly errors: readonly string[] }> => {
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
      result: await action(),
      logs,
      errors,
    };
  } finally {
    console.log = originalLog;
    console.error = originalError;
  }
};

const liveRuntimeForTest = liveActionRuntime as {
  console: RiceConsole;
  process: ProcessRunner;
};

test("main prints top-level help and exits zero", async () => {
  const { result, logs, errors } = await captureConsole(() => Effect.runPromise(main(["rice"])));
  assert.equal(result, 0);
  assert.match(logs.join("\n"), /Usage: rice <COMMAND>/);
  assert.deepEqual(errors, []);
});

test("main prints parser errors and exits one", async () => {
  const { result, logs, errors } = await captureConsole(() =>
    Effect.runPromise(main(["rice", "wat"])),
  );
  assert.equal(result, 1);
  assert.deepEqual(logs, []);
  assert.match(errors.join("\n"), /unknown command: wat/);
  assert.match(errors.join("\n"), /Usage: rice <COMMAND>/);
});

test("main prints runtime failures and exits one", async () => {
  const argv = process.platform === "darwin" ? ["rice", "nixos", "build"] : ["rice", "darwin", "build"];
  const expected = process.platform === "darwin" ? /Requires Linux/ : /Requires macOS/;

  const { result, errors } = await captureConsole(() => Effect.runPromise(main(argv)));
  assert.equal(result, 1);
  assert.match(errors.join("\n"), expected);
});

test("main returns zero on successful command execution", async () => {
  const seen = {
    info: [] as string[],
    ok: [] as string[],
    err: [] as string[],
    preview: [] as string[][],
    commands: [] as string[][],
  };
  const originalConsole = liveRuntimeForTest.console;
  const originalProcess = liveRuntimeForTest.process;

  liveRuntimeForTest.console = {
    ok: (message) => {
      seen.ok.push(message);
    },
    err: (message) => {
      seen.err.push(message);
    },
    info: (message) => {
      seen.info.push(message);
    },
    preview: (command) => {
      seen.preview.push([...command]);
    },
  };
  liveRuntimeForTest.process = {
    run: (command) =>
      Effect.sync(() => {
        seen.commands.push([...command]);
      }),
  };

  try {
    const code = await Effect.runPromise(main(["rice", "flake", "check"]));
    assert.equal(code, 0);
    assert.deepEqual(seen.commands, [["nix", "flake", "check", "."]]);
    assert.deepEqual(seen.preview, [["nix", "flake", "check", "."]]);
    assert.deepEqual(seen.info, ["Checking flake..."]);
    assert.deepEqual(seen.ok, ["Flake check passed"]);
    assert.deepEqual(seen.err, []);
  } finally {
    liveRuntimeForTest.console = originalConsole;
    liveRuntimeForTest.process = originalProcess;
  }
});
