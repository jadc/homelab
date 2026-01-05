{ config, lib, pkgs, ... }:

let
    name = "jellyfin";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

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

        port = mkOption {
            type = types.port;
            default = 8096;
            description = "Port on which Jellyfin listens";
        };
    };
    config = lib.mkIf cfg.enable {
        # Create user and group
        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;

                # GPU access for hardware transcoding
                extraGroups = [ "render" "video" ];
            };
            groups = {
                ${cfg.group} = {};
                render = {};
                video = {};
            };
        };

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
    };
}
