{ config, inputs, pkgs, ... }:

{
    imports = [ inputs.pi.nixosModules.default ];

    systemd.services.pi-update-extensions = {
        description = "Update Pi extensions";
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        path = [ pkgs.git pkgs.nodejs ];
        environment.HOME = config.users.users.root.home;
        serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "/run/current-system/sw/bin/pi update --extensions";
        };
    };

    systemd.timers.pi-update-extensions = {
        description = "Update Pi extensions daily";
        wantedBy = [ "timers.target" ];
        timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
        };
    };
}
