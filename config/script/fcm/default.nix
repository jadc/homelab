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
        ];

        systemd.tmpfiles.rules = [
            "L+ /run/secrets/webhook - - - - ${inputs.secrets}/webhook"
            "L+ /run/secrets/youtube - - - - ${inputs.secrets}/youtube.json"
        ];

        systemd.services.fcm = {
            description = "FCM Snooper";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            path = [ pkgs.ffmpeg pkgs.git ];

            serviceConfig = {
                ExecStartPre = "${pkgs.uv}/bin/uv tool install --python ${pkgs.python3}/bin/python3 instarec@git+https://github.com/jadc/instarec";
                ExecStart = "${pkgs.uv}/bin/uv run --python ${pkgs.python3}/bin/python3 ${./fcm.py}";
                Environment = "PYTHONUNBUFFERED=1";
                Restart = "always";
                RestartSec = 5;
            };
        };
    };
}
