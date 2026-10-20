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
            "L+ /run/secrets/cookies_ig - - - - ${inputs.secrets}/cookies_ig"
        ];

        systemd.services.fcm = {
            description = "FCM Snooper";
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];

            path = [ pkgs.ffmpeg pkgs.git ];

            # uv builds a new environment per fcm.py store path and never removes old ones;
            # use a dedicated cache and clear stale entries while the cache lock is free
            environment.UV_CACHE_DIR = "/var/cache/${name}";

            serviceConfig = {
                CacheDirectory = name;
                ExecStartPre = [
                    "${pkgs.coreutils}/bin/rm -rf /var/cache/${name}/environments-v2"
                    "${pkgs.uv}/bin/uv cache prune"
                    "${pkgs.uv}/bin/uv tool install --python ${pkgs.python3}/bin/python3 instarec"
                ];
                ExecStart = "${pkgs.uv}/bin/uv run --python ${pkgs.python3}/bin/python3 ${./fcm.py}";
                Environment = "PYTHONUNBUFFERED=1";
                Restart = "always";
                RestartSec = 5;
            };
        };
    };
}
