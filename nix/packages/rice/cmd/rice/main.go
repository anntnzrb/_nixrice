package main

import (
	"os"

	"liberion/rice/internal/rice"
)

// version is set via ldflags at build time.
var version = "dev"

func main() {
	_ = version
	os.Exit(rice.Main(os.Args[1:]))
}
