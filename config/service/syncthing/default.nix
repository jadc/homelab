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
            example = "/data/sync";
        };

        user = mkOption {
            type = types.str;
            default = "syncthing";
            description = "User account under which Syncthing runs";
        };

        group = mkOption {
            type = types.str;
            default = "syncthing";
            description = "Group under which Syncthing runs";
        };
    };

    config = let
        cfg = config.homelab.service.${name};
    in lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = [
            "d ${cfg.root} 0755 ${cfg.user} ${cfg.group} - -"
        ];

        services.syncthing = {
            enable = true;
            openDefaultPorts = true;
            dataDir = cfg.root;
            group = cfg.group;
            user = cfg.user;
        };
    };
}
