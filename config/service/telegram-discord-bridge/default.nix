{ config, lib, pkgs, ... }:

let
    name = "telegram-discord-bridge";
    cfg = config.homelab.service.${name};

    repo = "https://github.com/hyp3rd/telegram-discord-bridge.git";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        configFile = mkOption {
            type = types.str;
            description = "Path to the config.yml file";
        };
    };

    config = lib.mkIf cfg.enable {
        systemd.services.${name} = {
            description = "Telegram to Discord Bridge";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.uv}/bin/uv run --directory /var/lib/${name}/repo forwarder.py --start";
                Restart = "on-failure";
                RestartSec = 10;
                WorkingDirectory = "/var/lib/${name}";
                DynamicUser = true;
                StateDirectory = name;
            };

            environment = {
                UV_CACHE_DIR = "/var/lib/${name}/.cache/uv";
                UV_PYTHON_DOWNLOADS = "never";
                UV_PYTHON = "${pkgs.python3}/bin/python3";
            };

            path = [ pkgs.git pkgs.file ];

            preStart = ''
                if [ -d repo ]; then
                    ${pkgs.git}/bin/git -C repo pull --ff-only
                else
                    ${pkgs.git}/bin/git clone ${repo} repo
                fi
                ln -sf ${cfg.configFile} repo/config.yml
            '';
        };
    };
}
