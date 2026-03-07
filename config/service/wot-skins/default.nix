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

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which the app runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which the app runs";
        };

        contentDir = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "External path to symlink as the app's static/content directory at runtime";
        };
    };

    config = lib.mkIf cfg.enable {
        # Create user and group
        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
            };
            groups.${cfg.group} = {};
        };

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
            runDir = if cfg.contentDir != null
                then "/var/lib/${name}/build"
                else "${build}/build";

            setupScript = pkgs.writeShellScript "${name}-setup" ''
                rm -rf "$STATE_DIRECTORY/build"
                cp -r --no-preserve=mode ${build}/build "$STATE_DIRECTORY/build"
                rm -rf "$STATE_DIRECTORY/build/client/content"
                ln -sf ${cfg.contentDir} "$STATE_DIRECTORY/build/client/content"
            '';
        in {
            description = "WoT Skins";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.nodejs}/bin/node ${runDir}";
                Restart = "on-failure";
                RestartSec = 10;
                User = cfg.user;
                Group = cfg.group;
                StateDirectory = name;
            } // lib.optionalAttrs (cfg.contentDir != null) {
                ExecStartPre = "${setupScript}";
            };

            environment = {
                PORT = toString cfg.port;
                NODE_ENV = "production";
            };
        };
    };
}
