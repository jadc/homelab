{ config, lib, pkgs, ... }:

let
    name = "t3code";
    cfg = config.homelab.service.${name};
    dataDir = cfg.dataDir;
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption "T3 Code server, a web GUI for coding agents";

        package = mkPackageOption pkgs "t3code" { };

        user = mkOption {
            type = types.str;
            default = "root";
            description = "User account under which the T3 Code server (and its agents) runs";
        };

        host = mkOption {
            type = types.str;
            default = "0.0.0.0";
            description = "Interface the HTTP/WebSocket server binds to";
        };

        port = mkOption {
            type = types.port;
            default = 3773;
            description = "Port for the HTTP/WebSocket server";
        };

        dataDir = mkOption {
            type = types.str;
            default = "/var/lib/${name}";
            description = "T3 Code data directory (T3CODE_HOME)";
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = [ cfg.package ];

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        systemd.tmpfiles.rules = [
            "d ${dataDir} 0700 ${cfg.user} - - -"
        ];

        systemd.services.${name} = {
            description = "T3 Code server";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = [ "/run/current-system/sw" ];
            serviceConfig = {
                User = cfg.user;
                WorkingDirectory = dataDir;
                ExecStart = lib.escapeShellArgs [
                    "${cfg.package}/bin/t3" "serve"
                    "--mode" "web"
                    "--host" cfg.host
                    "--port" (toString cfg.port)
                    "--base-dir" dataDir
                    dataDir
                ];
                Restart = "on-failure";
                RestartSec = 5;
            };
        };
    };
}
