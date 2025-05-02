# homelab
The declarative NixOS configuration of my personal home lab.

## Installation
TODO

## Testing
To create a virtual machine with this configuration, first build it:

```sh 
nixos-rebuild build-vm --flake .#jadlab
```

Then, run it:

```sh
./result/bin/run-jadlab
```
