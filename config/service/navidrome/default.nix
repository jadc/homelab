{ config, lib, ... }:

let
    name = "navidrome";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Navidrome runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Navidrome runs";
        };

        port = mkOption {
            type = types.port;
            default = 4533;
            description = "Port on which Navidrome listens";
        };

        musicFolder = mkOption {
            type = types.str;
            description = "Path to the music library directory";
        };
    };

    config = lib.mkIf cfg.enable {
        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
            };
            groups.${cfg.group} = {};
        };

        services.navidrome = {
            enable = true;
            openFirewall = true;
            settings = {
                Address = "0.0.0.0";
                Port = cfg.port;
                MusicFolder = cfg.musicFolder;
            };
        };

        systemd.services.navidrome.serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
        };
    };
}
