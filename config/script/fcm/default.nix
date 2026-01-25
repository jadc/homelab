{ config, inputs, lib, pkgs, ... }:

let
    name = "fcm";
    cfg = config.homelab.script.${name};
in
{
    options.homelab.script.${name} = with lib; {
        enable = mkEnableOption name;
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = [
            pkgs.uv
            pkgs.python3
            pkgs.ffmpeg
        ];

        systemd.tmpfiles.rules = [
            "L+ /run/secrets/webhook - - - - ${inputs.secrets}/webhook"
        ];

        systemd.services.fcm = {
            description = "FCM Snooper";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                ExecStart = "${pkgs.uv}/bin/uv run --python ${pkgs.python3}/bin/python3 ${./fcm.py}";
                Restart = "always";
                RestartSec = 5;
            };
        };
    };
}
