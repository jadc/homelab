{ config, lib, ... }:

let
    name = "filebrowser";
    cfg = config.homelab.service.${name};
in
{
    # Copied from unstable, remove when in stable
    imports = [ ./filebrowser.nix ];

    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which File Browser runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which File Browser runs";
        };

        port = mkOption {
            type = types.port;
            default = 8080;
            description = "Port on which File Browser listens";
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

        services.filebrowser = {
            enable = true;
            openFirewall = true;
            user = cfg.user;
            group = cfg.group;
            settings.port = cfg.port;
        };
    };
}
