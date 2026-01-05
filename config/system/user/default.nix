{ config, lib, pkgs, ... }:

let
    name = "superuser";
    cfg = config.homelab.system.${name};
in
{
    options.homelab.system.${name} = {
        hashedPasswordFile = with lib; mkOption {
            type = types.str;
            description = "Path to a file containing a hashed password for root";
        };
    };

    config = {
        users.mutableUsers = false;
        users.users.root = {
            isSystemUser = true;
            shell = pkgs.bash;
            hashedPasswordFile = cfg.hashedPasswordFile;
        };
    };
}
