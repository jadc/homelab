{ config, lib, pkgs, ... }:

let
    name = "hdparm";
    cfg = config.homelab.system.${name};
in
{
    options.homelab.system.${name} = with lib; {
        enable = mkEnableOption "automatic power management for rotational drives";

        apmLevel = mkOption {
            type = types.int;
            description = "Advanced Power Management level (1-255). Lower values are more aggressive with power saving.";
            default = 127;
        };

        spindownTimeout = mkOption {
            type = types.int;
            description = "Spindown timeout in 5-second increments. 0 disables spindown, 1-240 = 5s to 20min, 241-251 = 30min to 5.5hr.";
            default = 240;
        };
    };

    config = lib.mkIf cfg.enable {
        services.udev.extraRules =
            let
                mkRule = as: lib.concatStringsSep ", " as;
                mkRules = rs: lib.concatStringsSep "\n" rs;
            in mkRules [( mkRule [
                ''ACTION=="add|change"''
                ''SUBSYSTEM=="block"''
                ''KERNEL=="sd[a-z]"''
                ''ATTR{queue/rotational}=="1"''
                ''RUN+="${pkgs.hdparm}/bin/hdparm -B ${toString cfg.apmLevel} -S ${toString cfg.spindownTimeout} /dev/%k"''
            ])];
    };
}
