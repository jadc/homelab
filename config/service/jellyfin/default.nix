{ config, lib, pkgs, ... }:

let
    name = "jellyfin";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        # TODO: probably move to *arr config
        root = mkOption {
            type = types.str;
            description = "Root directory for media";
        };

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Jellyfin runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Jellyfin runs";
        };
    };
    config = let
        cfg = config.homelab.service.${name};
    in lib.mkIf cfg.enable {
        # Create user and group
        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
            };
            groups.${cfg.group} = {};
        };

        # Create root directory with appropriate permissions
        # TODO: probably move to *arr config
        systemd.tmpfiles.rules = [
            "d ${cfg.root} 0755 ${cfg.user} ${cfg.group} - -"
            "d ${cfg.root}/movies 0755 ${cfg.user} ${cfg.group} - -"
            "d ${cfg.root}/shows 0755 ${cfg.user} ${cfg.group} - -"
        ];

        services.jellyfin = {
            enable = true;
            openFirewall = true;
            user = cfg.user;
            group = cfg.group;
        };

        environment.systemPackages = with pkgs; [
            jellyfin
            jellyfin-ffmpeg
            jellyfin-web
        ];

        # Open firewall for web UI on LAN
        networking.firewall.allowedTCPPorts = [ 8096 ];
    };
}
