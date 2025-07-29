{ config, lib, pkgs, ... }:

{
    options.homelab.system.superuser = {
        hashedPasswordFile = lib.mkOption {
            type = lib.types.str;
            description = "Path to a file containing a hashed password for root";
        };
    };

    config = {
        users.mutableUsers = false;
        users.users.root = {
            isSystemUser = true;
            shell = pkgs.bash;
            hashedPasswordFile = config.homelab.system.superuser.hashedPasswordFile;
            #uid = 994;
            #group = cfg.group;
        };
    };
}
