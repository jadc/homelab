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
            guiAddress = "0.0.0.0:8384";
        };

        # Open firewall for web UI
        networking.firewall.allowedTCPPorts = [ 8384 ];
    };
}
