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

        domain = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Domain name for Caddy reverse proxy";
            example = "photos.example.com";
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
            port = cfg.port;
            user = cfg.user;
            database.user = cfg.user;
            group = cfg.group;
        };

        # Configure Caddy reverse proxy if domain is specified
        homelab.service.caddy.proxies.${name} = lib.mkIf (cfg.domain != null) {
            domain = cfg.domain;
            port = cfg.port;

            # Required to support syncing large media
            reverseProxyConfig = ''
                flush_interval -1
            '';
            extraConfig = ''
                request_body {
                    max_size 50GB
                }
            '';
        };
    };
}
