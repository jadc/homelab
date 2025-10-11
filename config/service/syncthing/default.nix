{ config, lib, ... }:

let
    name = "syncthing";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        root = mkOption {
            type = types.str;
            default = "/var/lib/syncthing";
            description = "Root directory for synced files";
        };

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Syncthing runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Syncthing runs";
        };

        port = mkOption {
            type = types.port;
            default = 8384;
            description = "Port on which Syncthing web UI listens";
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

        # Configure service
        services.syncthing = {
            enable = true;
            dataDir = cfg.root;
            group = cfg.group;
            user = cfg.user;

            # Forwarding ports improves performance
            openDefaultPorts = true;

            # Disable telemetry
            settings.options.urAccepted = -1;

            # Allow WebUI access on LAN
            guiAddress = "0.0.0.0:${toString cfg.port}";
        };

        # Open firewall for web UI
        networking.firewall.allowedTCPPorts = [ cfg.port ];
    };
}
