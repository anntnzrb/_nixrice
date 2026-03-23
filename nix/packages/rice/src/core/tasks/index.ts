export type Platform = "darwin" | "linux";

export interface Task {
  readonly info: string;
  readonly cmd: readonly string[];
  readonly ok: string;
  readonly sudo: boolean;
  readonly platform?: Platform;
}

export { DARWIN_BUILD, DARWIN_SWITCH } from "./darwin.ts";
export { FLAKE_CHECK, FLAKE_FMT } from "./flake.ts";
export { NIX_OPTIMISE, NIX_REPAIR } from "./nix.ts";
export { NIXOS_BOOT, NIXOS_BUILD, NIXOS_SWITCH } from "./nixos.ts";
