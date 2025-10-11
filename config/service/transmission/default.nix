{ config, lib, pkgs, ... }:

let
    name = "transmission";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Transmission runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Transmission runs";
        };

        root = mkOption {
            type = types.str;
            description = "Directory where completed downloads are stored";
            example = "/data/downloads";
        };

        port = mkOption {
            type = types.port;
            default = 9091;
            description = "Port on which Transmission RPC listens";
        };

        settings = mkOption {
            type = types.attrs;
            default = {};
            description = "Additional settings for Transmission (merged with defaults)";
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

        # Transmission service configuration
        services.transmission = {
            enable = true;
            openFirewall = true;
            user = cfg.user;
            group = cfg.group;

            openRPCPort = true;
            openPeerPorts = true;

            settings = {
                download-dir = "${cfg.root}/complete";
                incomplete-dir-enabled = true;
                incomplete-dir = "${cfg.root}/incomplete";

                # RPC is the API servarr services use
                rpc-authentication-required = false;
                rpc-bind-address = "0.0.0.0";
                rpc-host-whitelist = "192.168.*.*";
                rpc-host-whitelist-enabled = true;
                rpc-port = cfg.port;
                rpc-whitelist = "127.0.0.1,192.168.*.*";
                rpc-whitelist-enabled = true;

                blocklist-enabled = true;
                blocklist-url = "https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz";
                cache-size-mb = 50;
                download-queue-size = 10;
                encryption = 1;
                port-forwarding-enabled = false;
                ratio-limit-enabled = true;
                utp-enabled = true;
            } // cfg.settings;
        };

        # Prioritize I/O of other services over transmission
        systemd.services.transmission.serviceConfig.IOSchedulingPriority = 7;
    };
}
