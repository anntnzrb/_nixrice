# AGENTS.md - Module System

Modules are the core implementation units that define feature behavior across platforms. Each module provides a single, focused capability using standardized patterns and the namespace.

### 1. Directory Structure

```
nix/modules/
├── darwin/     # macOS-specific modules
├── home/       # Home Manager modules (user-space)
├── nixos/      # NixOS system modules
├── shared/     # Cross-platform modules
└── default.nix # Auto-imports all modules
```

**Organization Pattern:**
```
<platform>/<category>/<feature>/default.nix
```

### 2. Platform Organization

**Platform-Specific Modules:**
- Platform directories contain modules that leverage platform-specific capabilities and APIs
- Each platform organizes modules by functional categories relevant to that environment
- Category names reflect the natural groupings of features for each platform

**Cross-Platform Modules:**
- Shared modules provide consistent functionality across different platforms
- Common abstractions that work regardless of underlying system
- Platform-agnostic features and utilities

**Organization Principles:**
```
<platform>/<category>/<feature>/default.nix
```
- Platform: The target system type
- Category: Functional grouping of related features
- Feature: Individual capability or tool

### 3. Module Implementation Pattern

**Key Principles:**
- **Single responsibility** - One feature per module
- **Conditional activation** - All config gated by `lib.mkIf cfg.enable`
- **Namespace isolation** - Use prefix exclusively
- **Option standardization** - Use helper functions

### 4. Cross-Module Integration

**Enabling Other Modules:**
Modules can activate other features as dependencies.

**Session Variable Integration:**
Reference `config.home.sessionVariables` for consistent tool selection across modules.

**Service Injection:**
Modules can add keybindings, autostart programs, or configuration to other services.

### 5. Module Types

**Simple Modules:**
Basic feature enablement with minimal configuration options.

**Complex Modules:**
Multi-file modules with subdirectories for organization, using imports to structure related functionality.

**Integration Modules:**
Modules that primarily orchestrate other modules and cross-platform abstractions.
