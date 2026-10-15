{ config, lib, ... }:

let
    name = "k3s";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        startOnBoot = mkOption {
            type = types.bool;
            default = true;
            description = "Whether k3s should start automatically on boot";
        };
    };

    config = lib.mkIf cfg.enable {
        services.k3s = {
            enable = true;
            role = "server";
        };

        networking.firewall.allowedTCPPorts = [ 6443 ];

        systemd.services.k3s.wantedBy = lib.mkIf (!cfg.startOnBoot) (lib.mkForce []);
    };
}
