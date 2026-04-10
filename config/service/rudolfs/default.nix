{ config, lib, pkgs, ... }:

let
    name = "rudolfs";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port to listen on";
        };

        dataDir = mkOption {
            type = types.str;
            description = "Path to LFS object storage directory";
        };

        hashedPasswordFile = mkOption {
            type = types.str;
            description = "Path to bcrypt hashed password file";
        };
    };

    config = lib.mkIf cfg.enable {
        homelab.service.docker.enable = true;

        systemd.tmpfiles.rules = [
            "d ${cfg.dataDir} 0755 root root - -"
        ];

        homelab.service.caddy.proxies.${name}.extraConfig = ''
            basic_auth {
                lfs ${lib.trim (builtins.readFile cfg.hashedPasswordFile)}
            }
        '';

        systemd.services.${name} = {
            description = "Rudolfs Git LFS server";
            after = [ "docker.service" "network-online.target" ];
            wants = [ "network-online.target" ];
            requires = [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];

            environment = {
                PORT = toString cfg.port;
                DATA_DIR = cfg.dataDir;
            };

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.docker}/bin/docker compose -p ${name} -f ${./docker-compose.yml} up";
                ExecStop = "${pkgs.docker}/bin/docker compose -p ${name} -f ${./docker-compose.yml} down";
                Restart = "on-failure";
                RestartSec = 10;
            };
        };
    };
}
