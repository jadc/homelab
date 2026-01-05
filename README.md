# homelab
The declarative NixOS configuration of my personal home lab.

The configuration of the system and services are exposed as custom options from each module in `config/system` and `config/service` respectively.

These options abstract the implementation details of setting up each service; consequently, this system is intended to be configured by setting said options in `configuration.nix` _only_.

## Installation
1. Place the SSH keys for your GitHub in `/root/.ssh`
2. Clone this repository into `/etc/nixos` as root user
3. On any configuration change, run `sudo nixos-rebuild switch --flake /etc/nixos`

There are a few services that have databases and therefore are not fully declarative. Their files are located in `/var/lib/`, and they can be safely copied and pasted over from an old system.

## Testing
To create a virtual machine with this configuration, simply run:

```sh
nix run
```

Ensure your GitHub SSH keys are in `~/.ssh`, otherwise this command will fail.
