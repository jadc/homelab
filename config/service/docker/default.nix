{ config, lib, ... }:

let
    name = "docker";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;
    };

    config = lib.mkIf cfg.enable {
        virtualisation.docker = {
            enable = true;

            # Cap the BuildKit cache; least-recently-used layers are evicted continuously
            daemon.settings.builder.gc = {
                enabled = true;
                defaultKeepStorage = "10GB";
            };

            # Remove stopped containers, unused images and networks, and build cache older than 3 days;
            # volumes are never pruned
            autoPrune = {
                enable = true;
                dates = "daily";
                flags = [ "--all" "--filter" "until=72h" ];
            };
        };

        systemd.tmpfiles.rules = [
            "d /docker 0770 root docker -"
        ];
    };
}
