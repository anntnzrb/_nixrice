import type { Task } from "./index.ts";

export const NIX_OPTIMISE: Task = {
  info: "Optimizing nix store...",
  cmd: ["nix", "store", "optimise"],
  ok: "Nix store optimized",
  sudo: true,
};

export const NIX_REPAIR: Task = {
  info: "Repairing nix store...",
  cmd: ["nix-store", "--verify", "--check-contents", "--repair"],
  ok: "Nix store repaired",
  sudo: true,
};
