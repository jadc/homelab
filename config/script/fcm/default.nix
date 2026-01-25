{ pkgs, ... }:

{
    environment.systemPackages = [
        pkgs.uv
        pkgs.ffmpeg
    ];
}
