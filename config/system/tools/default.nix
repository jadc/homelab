# Generic system administration tools

{ pkgs, ... }:

{
    environment.systemPackages = with pkgs; [
        git
        htop
        tmux
        vim
    ];
}
