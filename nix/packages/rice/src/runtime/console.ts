export interface RiceConsole {
  readonly ok: (message: string) => void;
  readonly err: (message: string) => void;
  readonly info: (message: string) => void;
  readonly preview: (command: readonly string[]) => void;
}

const GREEN = "\x1b[1;32m";
const RED = "\x1b[1;31m";
const BLUE = "\x1b[1;34m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

export const ok = (message: string): void => {
  console.log(`${GREEN}✓${RESET} ${message}`);
};

export const err = (message: string): void => {
  console.error(`${RED}✗${RESET} ${message}`);
};

export const info = (message: string): void => {
  console.log(`${BLUE}→${RESET} ${message}`);
};

export const preview = (command: readonly string[]): void => {
  console.log(`${DIM}$ ${command.join(" ")}${RESET}`);
};

export const liveConsole: RiceConsole = {
  ok,
  err,
  info,
  preview,
};

export const silentConsole: RiceConsole = {
  ok: () => {},
  err: () => {},
  info: () => {},
  preview: () => {},
};
