{ config, lib, pkgs, ... }:

let
    name = "hd-idle";
    cfg = config.homelab.system.${name};
in
{
    options.homelab.system.${name} = with lib; {
        enable = mkEnableOption "hd-idle daemon for disk spin-down management";

        spindownTime = mkOption {
            type = types.int;
            default = 0;
            description = "Spin-down time in seconds for all disks. 0 disables spin-down.";
            example = 1800;
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.hd-idle ];

        systemd.services.hd-idle = {
            description = "hd-idle daemon";
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = 10;
                ExecStartPre = "-${pkgs.procps}/bin/pkill hd-idle";
                ExecStart = "${pkgs.hd-idle}/bin/hd-idle -d -i ${toString cfg.spindownTime}";
                ExecStop = "${pkgs.procps}/bin/pkill hd-idle";
            };
        };
    };
}
