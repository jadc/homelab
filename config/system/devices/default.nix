{ config, lib, ... }:

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
            };
        });
    };

    config = let
        cfg = config.homelab.system.${name};
        enabled = lib.filterAttrs (name: x: x.enable) cfg;
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
    };
}
