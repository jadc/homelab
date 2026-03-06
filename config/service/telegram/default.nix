{ config, lib, pkgs, ... }:

let
    name = "telegram";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        environmentFile = mkOption {
            type = types.str;
            description = "Path to environment file containing TELEGRAM_API_ID, TELEGRAM_API_HASH, DISCORD_WEBHOOK_URL, and TELEGRAM_CHANNELS";
        };
    };

    config = lib.mkIf cfg.enable {
        systemd.services.${name} = {
            description = "Telegram to Discord Forwarder";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.uv}/bin/uv run ${./telegram.py}";
                Restart = "on-failure";
                RestartSec = 10;
                WorkingDirectory = "/var/lib/${name}";
                DynamicUser = true;
                StateDirectory = name;
                EnvironmentFile = cfg.environmentFile;
            };

            environment = {
                UV_CACHE_DIR = "/var/lib/${name}/.cache/uv";
                UV_PYTHON_DOWNLOADS = "never";
                UV_PYTHON = "${pkgs.python3}/bin/python3";
            };
        };
    };
}
