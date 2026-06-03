package rice

import (
	"fmt"
	"io"
	"os"
	"strings"
)

// ANSI escape sequences for colored output.
const (
	green = "\x1b[1;32m"
	red   = "\x1b[1;31m"
	blue  = "\x1b[1;34m"
	dim   = "\x1b[2m"
	reset = "\x1b[0m"
)

// Stdout and Stderr are the output writers used by all console helpers.
// Tests may replace these with buffers.
var (
	Stdout io.Writer = os.Stdout
	Stderr io.Writer = os.Stderr
)

// OK prints a green success line to w.
func OK(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s✓%s %s\n", green, reset, msg)
}

// Err prints a red error line to w.
func Err(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s✗%s %s\n", red, reset, msg)
}

// Info prints a blue informational line to w.
func Info(w io.Writer, msg string) {
	fmt.Fprintf(w, "%s→%s %s\n", blue, reset, msg)
}

// Preview prints the rendered command line to w (dimmed, prefixed with $).
func Preview(w io.Writer, cmd []string) {
	fmt.Fprintf(w, "%s$ %s%s\n", dim, strings.Join(cmd, " "), reset)
}
