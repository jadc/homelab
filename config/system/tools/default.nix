# Generic system administration tools

{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        exiftool
        git
        btop
        herdr
        pciutils
        vim
    ];

    environment.variables.EDITOR = "vim";
}
