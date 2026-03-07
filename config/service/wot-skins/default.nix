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
    };

    config = lib.mkIf cfg.enable {
        systemd.services.${name} = let
            node_modules = pkgs.stdenv.mkDerivation {
                name = "${name}-node_modules";
                src = repo;
                nativeBuildInputs = [ pkgs.bun ];
                buildPhase = ''
                    cd app
                    bun install --frozen-lockfile
                '';
                installPhase = ''
                    mkdir -p $out
                    cp -r app/node_modules $out/
                '';
            };

            build = pkgs.stdenv.mkDerivation {
                name = "${name}-build";
                src = repo;
                nativeBuildInputs = [ pkgs.bun pkgs.nodejs ];
                buildPhase = ''
                    cd app
                    cp -r ${node_modules}/node_modules .
                    bun run build
                '';
                installPhase = ''
                    mkdir -p $out
                    cp -r app/build $out/
                    cp -r ${node_modules}/node_modules $out/
                    cp app/package.json $out/
                '';
            };
        in {
            description = "WoT Skins";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.nodejs}/bin/node ${build}/build";
                Restart = "on-failure";
                RestartSec = 10;
                DynamicUser = true;
                StateDirectory = name;
            };

            environment = {
                PORT = toString cfg.port;
                NODE_ENV = "production";
            };
        };
    };
}
