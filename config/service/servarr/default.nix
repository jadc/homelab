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
            apiKeyFile = mkOption {
                type = types.str;
                description = "Path to API key file for Sonarr";
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
            apiKeyFile = mkOption {
                type = types.str;
                description = "Path to API key file for Radarr";
            };
        };

        prowlarr = {
            enable = mkEnableOption "Prowlarr" // {
                default = cfg.enable;
            };
        };

        flaresolverr = {
            enable = mkEnableOption "Flaresolverr" // {
                default = cfg.prowlarr.enable;
            };
        };

        recyclarr = {
            enable = mkEnableOption "Recyclarr" // {
                default = cfg.enable;
            };
            user = mkOption {
                type = types.str;
                default = "recyclarr";
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

        # Prowlarr configuration
        services.flaresolverr = lib.mkIf cfg.flaresolverr.enable {
            enable = true;
            openFirewall = true;
        };

        # Bazarr configuration
        services.bazarr = lib.mkIf cfg.bazarr.enable {
            enable = true;
            user = cfg.bazarr.user;
            group = cfg.group;
        };

        # Recyclarr configuration
        services.recyclarr = lib.mkIf cfg.recyclarr.enable {
            enable = true;
            user = cfg.recyclarr.user;
            group = cfg.group;

            # https://raw.githubusercontent.com/imjustleaving/ServersatHome/refs/heads/main/recyclarr.yml
            configuration = {
                sonarr.web-1080p-v4 = {
                    api_key._secret = "/run/credentials/recyclarr.service/sonarr-api_key";
                    base_url = "http://localhost:8989";
                    delete_old_custom_formats = true;
                    replace_existing_custom_formats = true;

                    include = [
                        { template = "sonarr-quality-definition-series"; }
                        { template = "sonarr-v4-quality-profile-web-1080p"; }
                        { template = "sonarr-v4-custom-formats-web-1080p"; }
                        { template = "sonarr-v4-quality-profile-web-2160p"; }
                        { template = "sonarr-v4-custom-formats-web-2160p"; }
                    ];

                    custom_formats = [
                        {
                            trash_ids = [
                                "9b27ab6498ec0f31a3353992e19434ca" # DV (WEBDL)
                            ];
                            assign_scores_to = [ { name = "WEB-2160p"; } ];
                        }
                        {
                            trash_ids = [
                                "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                                "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                                "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                                "06d66ab109d4d2eddb2794d21526d140" # Retags
                                "1b3994c551cbb92a2c781af061f4ab44" # Scene
                            ];
                            assign_scores_to = [ { name = "WEB-2160p"; } ];
                        }
                        {
                            trash_ids = [
                                "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                            ];
                            assign_scores_to = [ { name = "WEB-2160p"; } ];
                        }
                        {
                            trash_ids = [
                                "2016d1676f5ee13a5b7257ff86ac9a93" # SDR
                            ];
                            assign_scores_to = [ { name = "WEB-2160p"; } ];
                        }
                        {
                            trash_ids = [
                                "32b367365729d530ca1c124a0b180c64" # Bad Dual Groups
                                "82d40da2bc6923f41e14394075dd4b03" # No-RlsGroup
                                "e1a997ddb54e3ecbfe06341ad323c458" # Obfuscated
                                "06d66ab109d4d2eddb2794d21526d140" # Retags
                                "1b3994c551cbb92a2c781af061f4ab44" # Scene
                            ];
                            assign_scores_to = [ { name = "WEB-1080p"; } ];
                        }
                        {
                            trash_ids = [
                                "9b64dff695c2115facf1b6ea59c9bd07" # x265 (no HDR/DV)
                            ];
                            assign_scores_to = [ { name = "WEB-1080p"; } ];
                        }
                    ];
                };

                radarr.uhd-bluray-web = {
                    api_key._secret = "/run/credentials/recyclarr.service/radarr-api_key";
                    base_url = "http://localhost:7878";
                    delete_old_custom_formats = true;
                    replace_existing_custom_formats = true;

                    include = [
                        { template = "radarr-quality-definition-movie"; }
                        { template = "radarr-quality-profile-uhd-bluray-web"; }
                        { template = "radarr-custom-formats-uhd-bluray-web"; }
                        { template = "radarr-quality-profile-hd-bluray-web"; }
                        { template = "radarr-custom-formats-hd-bluray-web"; }
                    ];

                    custom_formats = [
                        {
                            trash_ids = [
                                "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                            ];
                            assign_scores_to = [ { name = "UHD Bluray + WEB"; } ];
                        }
                        {
                            trash_ids = [
                                "923b6abef9b17f937fab56cfcf89e1f1" # DV (WEBDL)
                            ];
                            assign_scores_to = [ { name = "UHD Bluray + WEB"; } ];
                        }
                        {
                            trash_ids = [
                                "9c38ebb7384dada637be8899efa68e6f" # SDR
                            ];
                            assign_scores_to = [ { name = "UHD Bluray + WEB"; } ];
                        }
                        {
                            trash_ids = [
                                "9f6cbff8cfe4ebbc1bde14c7b7bec0de" # IMAX Enhanced
                            ];
                            assign_scores_to = [ { name = "HD Bluray + WEB"; } ];
                        }
                    ];
                };

                sonarr.anime = {
                    api_key._secret = "/run/credentials/recyclarr.service/sonarr-api_key";
                    base_url = "http://localhost:8989";
                    delete_old_custom_formats = true;
                    replace_existing_custom_formats = true;

                    include = [
                        { template = "sonarr-quality-definition-anime"; }
                        { template = "sonarr-v4-quality-profile-anime"; }
                        { template = "sonarr-v4-custom-formats-anime"; }
                    ];
                };

                radarr.anime = {
                    api_key._secret = "/run/credentials/recyclarr.service/radarr-api_key";
                    base_url = "http://localhost:7878";
                    delete_old_custom_formats = true;
                    replace_existing_custom_formats = true;

                    include = [
                        { template = "radarr-quality-definition-anime"; }
                        { template = "radarr-quality-profile-anime"; }
                        { template = "radarr-custom-formats-anime"; }
                    ];
                };
            };
        };

        # Recyclarr secrets handling
        systemd.services.recyclarr.serviceConfig.LoadCredential = [
            "radarr-api_key:${cfg.radarr.apiKeyFile}"
            "sonarr-api_key:${cfg.sonarr.apiKeyFile}"
        ];
    };
}
