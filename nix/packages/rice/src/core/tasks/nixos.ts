import type { Task } from "./index.ts";

export const NIXOS_BUILD: Task = {
  info: "Building NixOS...",
  cmd: ["nixos-rebuild", "build", "--flake", ".#"],
  ok: "NixOS build complete",
  sudo: false,
  platform: "linux",
};

export const NIXOS_BOOT: Task = {
  info: "Setting boot...",
  cmd: ["nixos-rebuild", "boot", "--sudo", "--flake", ".#"],
  ok: "Boot set",
  sudo: false,
  platform: "linux",
};

export const NIXOS_SWITCH: Task = {
  info: "Switching...",
  cmd: ["nixos-rebuild", "switch", "--sudo", "--flake", ".#"],
  ok: "NixOS switch complete",
  sudo: false,
  platform: "linux",
};
