# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a declarative NixOS configuration for a personal home lab server. The configuration exposes custom options through a modular architecture that abstracts implementation details of system and service setup.

## Key Commands

### Development and Testing
```sh
# Test configuration in a VM (requires GitHub SSH keys in ~/.ssh)
nix run

# Apply configuration changes on the actual system
sudo nixos-rebuild switch --flake /etc/nixos
```

## Architecture

### Module System
The codebase uses a custom option namespace `homelab.*` that abstracts all system and service configurations. All configuration should be done exclusively through these options in `configuration.nix`.

**Module auto-import pattern**: All `config/*/default.nix` files use identical auto-import logic:
```nix
let
    files = builtins.readDir ./.;
    dirs = builtins.filter
        (name: files.${name} == "directory")
        (builtins.attrNames files);
in {
    imports = builtins.map (dir: ./${dir}) dirs;
}
```
This automatically imports all subdirectories as NixOS modules.

### Directory Structure
- `flake.nix` - Flake entry point, defines system configuration for hostname "homelab"
- `configuration.nix` - **Single source of truth for all configuration**. Sets all `homelab.*` options
- `hardware-configuration.nix` - Hardware-specific configuration (not in repo)
- `config/` - All module definitions, split into two categories:
  - `config/system/` - System-level modules (user, devices, locale, tools, etc.)
  - `config/service/` - Service modules (caddy, jellyfin, wireguard, ssh)

### Module Pattern
Each service/system module follows this structure:
1. Defines options under `homelab.service.<name>` or `homelab.system.<name>`
2. Implements NixOS configuration in the `config` section using `lib.mkIf` guards
3. Each module is self-contained in `config/{service,system}/<name>/default.nix`

Example: The `caddy` module at config/service/caddy/default.nix:51-83 provides options for enabling Caddy, configuring TLS, and defining reverse proxies. The actual `services.caddy` configuration is generated from these options.

### Special Integrations
- **Secrets**: Managed via private flake input `secrets` (git+ssh://git@github.com/jadc/homelab-secrets)
  - Accessed in configuration as `${inputs.secrets}/filename`
  - Used for passwords, private keys, etc.
- **Device Mounts**: The `homelab.system.devices` option (config/system/devices/default.nix) provides declarative device mounting with automatic directory creation via systemd.tmpfiles
- **Service Proxying**: Caddy module provides `homelab.service.caddy.proxies.<name>` for declarative reverse proxy setup

## Configuration Philosophy
- **Never modify module files** (`config/**/*.nix`) to configure the system
- **Always configure via options** in `configuration.nix` using the `homelab.*` namespace
- This separation allows the modules to be reusable and the configuration to remain clean
