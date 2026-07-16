{ config, lib, pkgs, ... }:

let
    name = "music";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        user = mkOption {
            type = types.str;
            default = name;
            description = "User under which music services run";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which music services run";
        };

        libraryDir = mkOption {
            type = types.str;
            description = "Path to the organized music library";
        };

        downloadsDir = mkOption {
            type = types.str;
            description = "Path to the downloads directory for new music";
        };

        navidrome = {
            enable = mkEnableOption "navidrome";

            port = mkOption {
                type = types.port;
                default = 4533;
                description = "Port on which Navidrome listens";
            };

            environmentFile = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Path to environment file for Navidrome";
            };
        };

        slskd = {
            enable = mkEnableOption "slskd";

            port = mkOption {
                type = types.port;
                default = 5030;
                description = "Port on which the slskd web interface listens";
            };

            environmentFile = mkOption {
                type = types.path;
                description = "Path to environment file containing SLSKD_SLSK_USERNAME, SLSKD_SLSK_PASSWORD, and SLSKD_PASSWORD";
            };
        };

        beets = {
            enable = mkEnableOption "beets";

            interval = mkOption {
                type = types.str;
                default = "*:0/5";
                description = "Systemd calendar expression for how often to run the import";
            };
        };
    };

    config = lib.mkMerge [
        (lib.mkIf (cfg.navidrome.enable || cfg.slskd.enable || cfg.beets.enable) {
            users.users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
            };

            # Allow samba user to read/write music directories
            users.users.${config.homelab.service.samba.user}.extraGroups = [ cfg.group ];
            users.groups.${cfg.group} = {};

            # Create music directories
            systemd.tmpfiles.rules = [
                "d ${cfg.libraryDir} 2775 ${cfg.user} ${cfg.group} - -"
                "d ${cfg.downloadsDir} 2775 ${cfg.user} ${cfg.group} - -"
            ];
        })

        # Navidrome
        (lib.mkIf cfg.navidrome.enable {
            services.navidrome = {
                enable = true;
                openFirewall = true;
                settings = {
                    Address = "0.0.0.0";
                    Port = cfg.navidrome.port;
                    MusicFolder = cfg.libraryDir;
                };
            };

            systemd.services.navidrome.serviceConfig = {
                User = lib.mkForce cfg.user;
                Group = lib.mkForce cfg.group;
                EnvironmentFile = lib.mkIf (cfg.navidrome.environmentFile != null) cfg.navidrome.environmentFile;
            };
        })

        # slskd
        (lib.mkIf cfg.slskd.enable {
            services.slskd = {
                enable = true;
                openFirewall = true;
                user = cfg.user;
                group = cfg.group;
                environmentFile = cfg.slskd.environmentFile;
                settings = {
                    web.port = cfg.slskd.port;
                    directories.downloads = cfg.downloadsDir;
                    shares.directories = [ cfg.libraryDir ];
                };
            };

            # Open port for WebUI
            networking.firewall.allowedTCPPorts = [ cfg.slskd.port ];
        })

        # beets
        (lib.mkIf cfg.beets.enable (let
            # Auto-accepts confident matches, skips ambiguous ones.
            beetsConfig = pkgs.writeText "beets-config.yaml" ''
              directory: ${cfg.libraryDir}
              library: /var/lib/beets/library.db
              plugins: chroma fromfilename fetchart embedart lastgenre scrub deezer spotify
              import:
                move: yes
              fetchart:
                auto: yes
              embedart:
                auto: yes
              lastgenre:
                auto: yes
              scrub:
                auto: yes
            '';
        in {
            environment.systemPackages = [
                pkgs.beets
                (pkgs.writeShellScriptBin "beet-import" ''
                    exec sudo -u ${cfg.user} env BEETSDIR=/var/lib/beets \
                        ${pkgs.beets}/bin/beet -c ${beetsConfig} import "$@" ${cfg.downloadsDir}
                '')
            ];

            # Auto-tag and move downloads into library
            systemd.services.beets-import = {
                description = "Beets auto-import";

                # Home of system users (/var/empty) is read-only
                # beets writes to it, so this fixes that
                environment.HOME = "/var/lib/beets";

                serviceConfig = {
                    Type = "oneshot";
                    User = cfg.user;
                    Group = cfg.group;
                    StateDirectory = "beets";
                    ExecStart = "${pkgs.beets}/bin/beet -c ${beetsConfig} import -q --quiet-fallback skip ${cfg.downloadsDir}";
                };
            };

            systemd.timers.beets-import = {
                description = "Beets auto-import timer";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                    OnCalendar = cfg.beets.interval;
                    Persistent = true;
                };
            };
        }))
    ];
}
