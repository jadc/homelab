{ pkgs, ... }:

{
    environment.systemPackages = [
        pkgs.uv
        pkgs.python3
        pkgs.ffmpeg
    ];
}
