# Generic system administration tools

{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        btop
        exiftool
        gh
        git
        herdr
        pciutils
        vim
    ];

    environment.variables.EDITOR = "vim";

    programs.direnv.enable = true;
}
