{ lib, ... }:

{
    imports = [
        ./system
        ./service
    ];

    options.homelab.system = {
        timeZone = lib.mkOption {
            type = lib.types.str;
            default = "America/Edmonton";
            description = "The timezone of the system";
        };

        locale = lib.mkOption {
            type = lib.types.str;
            default = "en_CA.UTF-8";
            description = "The locale of the system";
        };
    };
}
