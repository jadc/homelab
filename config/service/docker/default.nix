{ config, lib, ... }:

let
    name = "docker";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        buildCacheSize = mkOption {
            type = types.str;
            default = "10GB";
            description = "Maximum size of the BuildKit cache, after which least-recently-used layers are evicted";
        };

        pruneAge = mkOption {
            type = types.str;
            default = "72h";
            description = "Minimum age of stopped containers, unused images and networks, and build cache removed by the daily prune";
        };
    };

    config = lib.mkIf cfg.enable {
        virtualisation.docker = {
            enable = true;

            # Cap the BuildKit cache; least-recently-used layers are evicted continuously
            daemon.settings.builder.gc = {
                enabled = true;
                defaultKeepStorage = cfg.buildCacheSize;
            };

            # Remove stopped containers, unused images and networks, and build cache older than pruneAge;
            # unused anonymous volumes are pruned separately below
            autoPrune = {
                enable = true;
                dates = "daily";
                flags = [ "--all" "--filter" "until=${cfg.pruneAge}" ];
            };
        };

        # docker system prune rejects the until filter with --volumes, so prune volumes separately
        systemd.services.docker-volume-prune = lib.mkIf config.virtualisation.docker.autoPrune.enable {
            description = "Prune unused anonymous Docker volumes";
            after = [ "docker.service" ];
            requires = [ "docker.service" ];
            startAt = config.virtualisation.docker.autoPrune.dates;
            serviceConfig.Type = "oneshot";
            script = "${config.virtualisation.docker.package}/bin/docker volume prune --force";
        };

        systemd.tmpfiles.rules = [
            "d /docker 0770 root docker -"
        ];
    };
}
