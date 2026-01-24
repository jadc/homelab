{ config, lib, ... }:

let
    name = "webhook";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which webhook runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which webhook runs";
        };

        port = mkOption {
            type = types.port;
            default = 9000;
            description = "Port on which webhook listens";
        };

        hooks = mkOption {
            type = types.unspecified;
            default = {};
            description = "Webhook hooks configuration";
        };
    };

    config = lib.mkIf cfg.enable {
        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
            };
            groups.${cfg.group} = {};
        };

        services.webhook = {
            enable = true;
            user = cfg.user;
            group = cfg.group;
            port = cfg.port;
            hooks = cfg.hooks;
            openFirewall = true;
        };
    };
}
