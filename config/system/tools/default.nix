# Generic system administration tools

{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        exiftool
        git
        btop
        pciutils
        tmux
        vim
    ];
}
