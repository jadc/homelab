{ config, pkgs, lib, ... }:

let
    name = "devices";
in
{
    options.homelab.system.${name} = with lib; mkOption {
        default = {};
        type = with types; attrsOf (submodule {
            options = {
                enable = mkEnableOption "this device mount" // {
                    default = true;
                };

                mountPoint = mkOption {
                    type = types.str;
                    description = "Path where the device will be mounted";
                    example = "/data";
                };

                device = mkOption {
                    type = types.str;
                    description = "Device to be mounted";
                    example = "/dev/sda1";
                };

                fsType = mkOption {
                    type = types.str;
                    description = "Type of file system";
                    default = "auto";
                };

                options = mkOption {
                    type = types.listOf types.str;
                    description = "Mount options";
                    default = [ "defaults" ];
                };

                group = mkOption {
                    type = types.nullOr types.str;
                    description = "Group that owns the mount point";
                    default = null;
                };

                permissions = mkOption {
                    type = types.str;
                    description = "Permissions on the mount point";
                    default = "755";
                };

                owner = mkOption {
                    type = types.str;
                    description = "User that owns the mount point";
                    default = "root";
                };

                powerManagement = {
                    enable = mkEnableOption "power management for this device" // {
                        default = false;
                    };

                    spindownTimeout = mkOption {
                        type = types.nullOr types.int;
                        description = "Spindown timeout in seconds (multiples of 5). Set to 0 to disable spindown.";
                        default = 1200; # 20 minutes
                        example = 600;
                    };

                    apmLevel = mkOption {
                        type = types.nullOr types.int;
                        description = "Advanced Power Management level (1-255). 1=max power saving, 255=max performance. 128-254 allows spindown.";
                        default = 128;
                        example = 128;
                    };
                };
            };
        });
    };

    config = let
        cfg = config.homelab.system.${name};
        enabled = lib.filterAttrs (name: x: x.enable) cfg;
        powerManaged = lib.filterAttrs (name: x: x.enable && x.powerManagement.enable) cfg;
    in {
        # Create mountPoint directory
        systemd.tmpfiles.rules = with lib;
            mapAttrsToList (name: x:
                let
                    group = if x.group != null then x.group else "-";
                in
                    "d ${x.mountPoint} ${x.permissions} ${x.owner} ${group} - -"
            ) enabled;

        # Mount device to mountPoint
        fileSystems = with lib; mkMerge (
            mapAttrsToList (name: x: {
                ${x.mountPoint} = {
                    device = x.device;
                    fsType = x.fsType;
                    options = x.options;
                };
            }) enabled
        );

        # Ensure hdparm is available
        environment.systemPackages = with pkgs; lib.mkIf (powerManaged != {}) [ hdparm ];

        # Power management for devices
        systemd.services = with lib; mkMerge (
            mapAttrsToList (name: x: {
                "hdparm-${name}" = {
                    description = "Power management for ${x.device}";
                    wantedBy = [ "multi-user.target" ];
                    after = [ "local-fs.target" ];
                    serviceConfig = {
                        Type = "oneshot";
                        RemainAfterExit = true;
                        ExecStart = let
                            spindownSecs = if x.powerManagement.spindownTimeout != null
                                then x.powerManagement.spindownTimeout
                                else 0;
                            # hdparm uses units of 5 seconds
                            spindownUnits = toString (spindownSecs / 5);
                            apmArg = if x.powerManagement.apmLevel != null
                                then "-B ${toString x.powerManagement.apmLevel}"
                                else "";
                            spindownArg = if spindownSecs > 0
                                then "-S ${spindownUnits}"
                                else "";
                        in "${pkgs.hdparm}/bin/hdparm ${apmArg} ${spindownArg} ${x.device}";
                    };
                };
            }) powerManaged
        );

    };
}
