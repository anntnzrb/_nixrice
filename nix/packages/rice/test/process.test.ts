import assert from "node:assert/strict";

import { test } from "bun:test";
import { Effect } from "effect";

import { liveProcessRunner } from "../src/runtime/process.ts";

test("live process runner reports missing commands", async () => {
  const result = await Effect.runPromise(
    Effect.either(liveProcessRunner.run(["__rice_missing_command__"])),
  );
  assert.equal(result._tag, "Left");
  assert.match(result.left.message, /__rice_missing_command__/);
});

test("live process runner reports signal exits as negative status", async () => {
  const result = await Effect.runPromise(
    Effect.either(liveProcessRunner.run(["sh", "-c", "kill -TERM $$"])),
  );
  assert.equal(result._tag, "Left");
  assert.match(result.left.message, /exit: -1/);
});
