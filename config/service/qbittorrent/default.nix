{ config, lib, pkgs, ... }:

let
    name = "qbittorrent";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which qBittorrent runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which qBittorrent runs";
        };

        root = mkOption {
            type = types.str;
            description = "Directory where downloads are stored";
            example = "/data/torrents";
        };

        port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port on which qBittorrent web UI listens";
        };

        settings = mkOption {
            type = types.attrs;
            default = {};
            description = "Additional settings for qBittorrent (deep-merged with defaults)";
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

        # Create download directories
        systemd.tmpfiles.rules = [
            "d ${cfg.root} 0755 ${cfg.user} ${cfg.group} - -"
            "d ${cfg.root}/complete 0755 ${cfg.user} ${cfg.group} - -"
            "d ${cfg.root}/incomplete 0755 ${cfg.user} ${cfg.group} - -"
        ];

        # qBittorrent service configuration
        services.qbittorrent = {
            enable = true;
            openFirewall = true;
            user = cfg.user;
            group = cfg.group;
            webuiPort = cfg.port;

            serverConfig = lib.recursiveUpdate {
                BitTorrent.Session = {
                    DefaultSavePath = "${cfg.root}/complete";
                    TempPath = "${cfg.root}/incomplete";
                    TempPathEnabled = true;
                };
                # Skip login on same machine (i.e. *arr access)
                Preferences.WebUI = {
                    AuthSubnetWhitelistEnabled = true;
                    AuthSubnetWhitelist = "127.0.0.1/32";
                    Password_PBKDF2 = ''"@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"'';
                };
            } cfg.settings;
        };

        # Prioritize I/O of other services over qBittorrent
        systemd.services.qbittorrent.serviceConfig.IOSchedulingPriority = 7;
    };
}
