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
        virtualisation.docker.enable = true;

        systemd.tmpfiles.rules = [
            "d /docker 0770 root docker -"
        ];
    };
}
