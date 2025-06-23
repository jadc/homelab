{ inputs, pkgs, ... }:

{
    users.mutableUsers = false;
    users.users.root = {
        isSystemUser = true;
        shell = pkgs.bash;
        hashedPasswordFile = "${inputs.secrets}/passwd.hash";
        #uid = 994;
        #group = cfg.group;
    };
}
