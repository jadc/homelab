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

    setupScript = pkgs.writeShellScript "${name}-setup" ''
        # Rebuild only when source changes
        if [ ! -f "$STATE_DIRECTORY/.rev" ] || [ "$(cat "$STATE_DIRECTORY/.rev")" != "${cfg.rev}" ]; then
            rm -rf "$STATE_DIRECTORY/app"
            cp -r ${repo}/app "$STATE_DIRECTORY/app"
            chmod -R u+w "$STATE_DIRECTORY/app"
            cd "$STATE_DIRECTORY/app"
            ${pkgs.bun}/bin/bun install --frozen-lockfile
            ${pkgs.bun}/bin/bun run build
            echo "${cfg.rev}" > "$STATE_DIRECTORY/.rev"
        fi

        ${lib.optionalString (cfg.contentDir != null) ''
            rm -rf "$STATE_DIRECTORY/app/build/client/content"
            ln -sf ${cfg.contentDir} "$STATE_DIRECTORY/app/build/client/content"
        ''}
    '';
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

        networking.firewall.allowedTCPPorts = [ cfg.port ];

        systemd.services.${name} = {
            description = "WoT Skins";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];

            serviceConfig = {
                Type = "simple";
                ExecStartPre = "${setupScript}";
                ExecStart = "${pkgs.bun}/bin/bun /var/lib/${name}/app/build";
                Restart = "on-failure";
                RestartSec = 10;
                User = cfg.user;
                Group = cfg.group;
                StateDirectory = name;
            };

            environment = {
                PORT = toString cfg.port;
                NODE_ENV = "production";
            };
        };
    };
}
