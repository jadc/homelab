{ lib, config, ... }:

{
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

    config = {
        time.timeZone = config.homelab.system.timeZone;
        i18n = let locale = config.homelab.system.locale; in {
            defaultLocale = locale;
            extraLocaleSettings = {
                LC_ADDRESS = locale;
                LC_IDENTIFICATION = locale;
                LC_MEASUREMENT = locale;
                LC_MONETARY = locale;
                LC_NAME = locale;
                LC_NUMERIC = locale;
                LC_PAPER = locale;
                LC_TELEPHONE = locale;
                LC_TIME = locale;
            };
        };
    };
}
