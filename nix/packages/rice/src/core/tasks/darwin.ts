import type { Task } from "./index.ts";

export const DARWIN_BUILD: Task = {
  info: "Building Darwin for {host}...",
  cmd: ["nix", "build", ".#darwinConfigurations.{host}.system"],
  ok: "Darwin build complete",
  sudo: false,
  platform: "darwin",
};

export const DARWIN_SWITCH: Task = {
  info: "Switching...",
  cmd: ["./result/sw/bin/darwin-rebuild", "switch", "--flake", ".#{host}"],
  ok: "Darwin switch complete",
  sudo: true,
  platform: "darwin",
};
