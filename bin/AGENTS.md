# AGENTS.md - Operational Tools

Operational scripts and utilities for managing the entire dotfiles system. These tools provide streamlined interfaces for building, deploying, and maintaining configurations across platforms.

### 1. Directory Structure

```
bin/
├── rice.sh         # Main operational interface
└── nix-install.sh  # Nix installation script
```

### 2. Main Operational Interface

**rice.sh** - Central command dispatcher for all system operations:
- Platform-aware command routing
- Consistent interface across NixOS, Darwin, and Home Manager
- Built-in validation and error handling
- Automated workflows for common tasks

**Core Principle:** Single script interface that abstracts platform differences and provides consistent operational experience.

### 3. Command Categories

**System Management:**
Platform-specific build and deployment commands that automatically detect the current environment and route to appropriate tools.

**Home Manager Operations:**
User environment management with explicit user@host targeting for precise control over configurations.

**Maintenance Utilities:**
Nix store cleanup, optimization, and repair operations for system health maintenance.

**Flake Management:**
Input updates, dependency management, and lockfile operations with automated git integration.

**Quality Assurance:**
Code formatting, validation, and pre-commit hook execution for maintaining code standards.

**Special Builds:**
ISO generation and specialized deployment configurations for different use cases.

### 4. Operational Patterns

**Platform Detection:**
Automatic platform identification with validation to ensure commands run on appropriate systems.

**Error Handling:**
Robust argument validation and early error detection with clear error messages and appropriate exit codes.

**Atomic Operations:**
Commands that combine related operations (build + activate) to reduce manual steps and potential inconsistencies.

**Git Integration:**
Automated commit generation for flake updates with consistent commit message formatting.

### 5. Usage Philosophy

**Always Use Script Wrappers:**
Never invoke nix commands directly - use the operational scripts to ensure consistent behavior and proper error handling.

**Fail Fast:**
Commands validate requirements early and provide clear feedback when prerequisites aren't met.

**Platform Abstraction:**
Common operations work consistently across platforms without requiring platform-specific knowledge.
