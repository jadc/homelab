{ config, lib, pkgs, ... }:

let
    name = "wot-skins";
    cfg = config.homelab.service.${name};

    repo = pkgs.fetchFromGitHub {
        owner = "jadc";
        repo = name;
        rev = cfg.rev;
        hash = cfg.hash;
    };
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        port = mkOption {
            type = types.port;
            default = 3000;
            description = "Port the SvelteKit app listens on";
        };

        rev = mkOption {
            type = types.str;
            description = "Git revision to deploy";
        };

        hash = mkOption {
            type = types.str;
            description = "Hash of the fetched source (use lib.fakeHash to find it)";
        };

        contentDir = mkOption {
            type = types.str;
            description = "Host path to bind mount into the container for content";
        };
    };

    config = lib.mkIf cfg.enable {
        homelab.service.docker.enable = true;

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        systemd.services.${name} = {
            description = "WoT Skins";
            after = [ "docker.service" "network-online.target" ];
            wants = [ "network-online.target" ];
            requires = [ "docker.service" ];
            wantedBy = [ "multi-user.target" ];

            environment = {
                BUILD_CONTEXT = toString repo;
                PORT = toString cfg.port;
                CONTENT_DIR = cfg.contentDir;
            };

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.docker}/bin/docker compose -p ${name} -f ${./docker-compose.yml} up --build";
                ExecStop = "${pkgs.docker}/bin/docker compose -p ${name} -f ${./docker-compose.yml} down";
                Restart = "on-failure";
                RestartSec = 10;
            };
        };
    };
}
