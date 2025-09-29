# AGENTS.md - Home Configurations

Home configurations define user-specific environments and applications using Home Manager. Each configuration follows the `<arch>/<user@host>/default.nix` pattern.

### 1. Directory Structure

```
nix/homes/
├── <architecture>/
│   └── <user@host>/
│       └── default.nix # User environment configuration
```

### 2. Configuration Types

**Desktop Environments:**
- Full desktop setups with window managers, applications, and GUI tools
- Session variables for application integration
- Display and hardware-specific configurations

**Minimal Environments:**
- CLI-focused setups for servers or development
- Essential tools and shell configuration
- Terminal applications

**Platform-Specific:**
- Darwin homes leverage platform-specific applications and integrations
- Linux homes include X11/Wayland display configurations
- WSL homes focus on development and CLI tools

### 3. Configuration Philosophy

Home configurations are **user environment compositions** that define:
- Personal application preferences and feature selections
- Session variables for cross-application integration
- Host-specific customizations (displays, autostart programs)
- Development and workflow tool selection

**Key Principle:** Homes define **WHICH** features a user wants on each host, while modules define **HOW** those features are configured.

### 4. Common Patterns

**Session Variables:**
Central environment configuration consumed by modules for consistent integration across tools.

**Host-Specific Data:**
Include host-specific configurations like display settings, autostart programs, and hardware preferences as data structures.

**Modular Composition:**
Leverage nested attribute sets to organize related features while keeping unused options available but disabled.
