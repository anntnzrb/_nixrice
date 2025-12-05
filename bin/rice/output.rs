const GREEN: &str = "\x1b[1;32m";
const RED: &str = "\x1b[1;31m";
const BLUE: &str = "\x1b[1;34m";
const DIM: &str = "\x1b[2m";
const RESET: &str = "\x1b[0m";

pub fn success(msg: &str) { println!("{GREEN}✓{RESET} {msg}"); }
pub fn error(msg: &str) { eprintln!("{RED}✗{RESET} {msg}"); }
pub fn info(msg: &str) { println!("{BLUE}→{RESET} {msg}"); }

pub fn cmd(cmd: &str, args: &[&str]) {
    println!("{DIM}$ {} {}{RESET}", cmd, args.join(" "));
}
