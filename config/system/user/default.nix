{ lib, config, ... }:

{
    options.homelab.system = {
        user = lib.mkOption {
            default = "homelab";
            type = lib.types.str;
            description = "User to run the homelab services as";
        };
        group = lib.mkOption {
            default = "homelab";
            type = lib.types.str;
            description = "Group to run the homelab services as";
        };
    };

    config = {
        users = let cfg = config.homelab.system; in {
            groups.${cfg.group} = {
                gid = 993;
            };
            users.${cfg.user} = {
                uid = 994;
                isSystemUser = true;
                group = cfg.group;
            };
        };
    };
}
