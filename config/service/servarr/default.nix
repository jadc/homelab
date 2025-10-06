{ config, lib, ... }:

let
    name = "servarr";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption "servarr services";

        root = mkOption {
            type = types.str;
            description = "Root directory for media files";
            example = "/data/media";
        };

        group = mkOption {
            type = types.str;
            default = "media";
            description = "Common group for all media services";
        };

        sonarr = {
            enable = mkEnableOption "Sonarr" // {
                default = cfg.enable;
            };
            user = mkOption {
                type = types.str;
                default = "sonarr";
            };
        };

        radarr = {
            enable = mkEnableOption "Radarr" // {
                default = cfg.enable;
            };
            user = mkOption {
                type = types.str;
                default = "radarr";
            };
        };

        prowlarr = {
            enable = mkEnableOption "Prowlarr" // {
                default = cfg.enable;
            };
        };

        bazarr = {
            enable = mkEnableOption "Bazarr" // {
                default = cfg.enable;
            };
            user = mkOption {
                type = types.str;
                default = "bazarr";
            };
        };
    };

    config = lib.mkIf cfg.enable {
        users = {
            # Create configured group
            groups.${cfg.group} = {};

            # Create users for enabled services
            users = lib.mkMerge [
                (lib.mkIf cfg.sonarr.enable {
                    ${cfg.sonarr.user} = {
                        isSystemUser = true;
                        group = cfg.group;
                    };
                })
                (lib.mkIf cfg.radarr.enable {
                    ${cfg.radarr.user} = {
                        isSystemUser = true;
                        group = cfg.group;
                    };
                })
                (lib.mkIf cfg.prowlarr.enable {
                    ${cfg.prowlarr.user} = {
                        isSystemUser = true;
                        group = cfg.group;
                    };
                })
                (lib.mkIf cfg.bazarr.enable {
                    ${cfg.bazarr.user} = {
                        isSystemUser = true;
                        group = cfg.group;
                    };
                })
            ];
        };

        # Create media directory structure
        systemd.tmpfiles.rules = [
            "d ${cfg.root} 0775 root ${cfg.group} - -"
            "d ${cfg.root}/movies 0775 root ${cfg.group} - -"
            "d ${cfg.root}/shows 0775 root ${cfg.group} - -"
        ];

        # Sonarr configuration
        services.sonarr = lib.mkIf cfg.sonarr.enable {
            enable = true;
            openFirewall = true;
            user = cfg.sonarr.user;
            group = cfg.group;
        };

        # Radarr configuration
        services.radarr = lib.mkIf cfg.radarr.enable {
            enable = true;
            openFirewall = true;
            user = cfg.radarr.user;
            group = cfg.group;
        };

        # Prowlarr configuration
        services.prowlarr = lib.mkIf cfg.prowlarr.enable {
            enable = true;
            openFirewall = true;
        };

        # Bazarr configuration
        services.bazarr = lib.mkIf cfg.bazarr.enable {
            enable = true;
            user = cfg.bazarr.user;
            group = cfg.group;
        };
    };
}
