{ config, lib, ... }:

let
    name = "immich";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        root = mkOption {
            type = types.str;
            default = "/var/lib/immich";
            description = "Root directory for media files";
        };

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Immich runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Immich runs";
        };

        port = mkOption {
            type = types.port;
            default = 2283;
            description = "Port on which Immich listens";
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
            "d ${cfg.root} 0775 ${cfg.user} ${cfg.group} - -"
        ];

        services.immich = {
            enable = true;

            mediaLocation = cfg.root;
            openFirewall = true;
            host = "0.0.0.0";
            port = cfg.port;
            user = cfg.user;
            database.user = cfg.user;
            group = cfg.group;
        };

        # Override systemd service config to allow group rwx permissions
        # Default UMask is 0077 (user-only), we change to 0007 (user+group)
        systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0007";
        systemd.services.immich-machine-learning.serviceConfig.UMask = lib.mkForce "0007";

        # Override tmpfiles mode to allow group rwx permissions
        # Default mode is 0700 (user-only), we change to 0770 (user+group)
        systemd.tmpfiles.settings.immich."${cfg.root}".e.mode = lib.mkForce "0770";
    };
}
