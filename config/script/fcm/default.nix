{ inputs, pkgs, ... }:

{
    environment.systemPackages = [
        pkgs.uv
        pkgs.python3
        pkgs.ffmpeg
    ];

    systemd.tmpfiles.rules = [
        "L+ /run/secrets/webhook - - - - ${inputs.secrets}/webhook"
    ];
}
