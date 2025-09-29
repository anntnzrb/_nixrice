# AGENTS.md - System Configurations

System configurations define host-specific hardware, networking, and platform settings. Each system follows the `<arch>/<hostname>/default.nix` pattern with optional hardware subdirectories.

### 1. Directory Structure

```
nix/systems/
├── <architecture>/
│   └── <hostname>/
│       ├── default.nix     # Main system configuration
│       ├── hardware/       # Hardware-specific modules (optional)
│       │   ├── default.nix # Hardware imports & filesystem
│       │   ├── cpu.nix     # CPU-specific settings
│       │   ├── gpu.nix     # Graphics configuration
│       │   └── kernel.nix  # Kernel parameters
│       └── readme.md       # Host documentation
```

### 2. Platform Types

**Production Systems:**
- `x86_64-linux/<host>` - Full NixOS installations
- `aarch64-darwin/<host>` - macOS systems

**Special Purpose:**
- `x86_64-do/<host>` - Digital Ocean deployments
- `x86_64-iso/<host>` - Live ISO generations

### 3. Configuration Philosophy

System configurations are **declarative host definitions** that focus on:
- Hardware-specific settings that cannot be abstracted
- Platform-level networking configuration
- Boot and filesystem requirements

**Key Principle:** Systems define **WHAT** features are enabled for each host, while modules define **HOW** features work.

### 4. Separation of Concerns

**System Level (this directory):**
- Hardware detection and drivers
- Filesystem layout and mount options
- Network interfaces and static configuration
- Platform-specific requirements
