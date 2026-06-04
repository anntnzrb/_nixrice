// Command rice is the NixOS/Darwin configuration management CLI.
package main

import (
	"os"

	"liberion/rice/internal/rice"
)

// version is the build version, set via ldflags at build time.
var version = "dev"

func main() {
	_ = version
	os.Exit(rice.Main(os.Args[1:]))
}
