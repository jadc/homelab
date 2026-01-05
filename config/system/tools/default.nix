# Generic system administration tools

{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        git
        htop
        pciutils
        tmux
        vim
    ];
}
