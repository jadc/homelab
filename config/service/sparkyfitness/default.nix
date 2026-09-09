{ config, lib, ... }:

let
    name = "sparkyfitness";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which SparkyFitness runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which SparkyFitness runs";
        };

        domain = mkOption {
            type = types.str;
            description = "Public domain used to access SparkyFitness";
        };

        port = mkOption {
            type = types.port;
            default = 8098;
            description = "Internal nginx port serving the SparkyFitness frontend";
        };

        stateDir = mkOption {
            type = types.path;
            default = "/var/lib/sparkyfitness";
            description = "Directory for uploads, backups, and temporary files";
        };

        environmentFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Environment file containing SparkyFitness database and authentication secrets";
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

        services.sparkyfitness = {
            enable = true;
            user = cfg.user;
            group = cfg.group;
            frontendUrl = "https://${cfg.domain}";
            environmentFile = cfg.environmentFile;
            stateDir = cfg.stateDir;
        };

        services.nginx.virtualHosts.localhost = {
            default = true;

            # Change port of nginx, which SparkyFitness depends on
            listen = [{ addr = "127.0.0.1"; port = cfg.port; }];
        };
    };
}
