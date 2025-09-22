{ lib, ... }:

# Imports all sibling directories to this file
let
    subdirs = lib.filterAttrs (name: type:
        type == "directory" &&
        builtins.pathExists (./. + "/${name}/default.nix")
    ) builtins.readDir ./.;
in {
    imports = map (name: ./. + "/${name}") (lib.attrNames subdirs);
}
