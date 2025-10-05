{ config, lib, pkgs, ... }:

let
    name = "jellyfin";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        root = mkOption {
            type = types.str;
            default = "/var/lib/jellyfin";
            description = "Root directory for Jellyfin data";
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
        systemd.tmpfiles.rules = [
            "d ${cfg.root} 0755 ${cfg.user} ${cfg.group} - -"
        ];

        services.jellyfin = {
            enable = true;
            openFirewall = true;
            dataDir = cfg.root;
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
