{ config, lib, pkgs, ... }:

let
    name = "jellyfin";
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
