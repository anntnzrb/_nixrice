import type { Task } from "./index.ts";

export const FLAKE_CHECK: Task = {
  info: "Checking flake...",
  cmd: ["nix", "flake", "check", "."],
  ok: "Flake check passed",
  sudo: false,
};

export const FLAKE_FMT: Task = {
  info: "Formatting...",
  cmd: ["pre-commit", "run", "--all-files"],
  ok: "Format complete",
  sudo: false,
};
