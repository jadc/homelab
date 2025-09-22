{ config, lib, ... }:

let
    name = "devices";
in
{
    options.homelab.system.${name} = with lib; mkOption {
        type = with types; attrsOf (submodule {
            options = {
                enable = mkEnableOption "this device mount" // {
                    default = true;
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
        enabled = lib.filterAttrs (mountPoint: x: x.enable) cfg;
    in {
        # Create mountPoint directory
        systemd.tmpfiles.rules = with lib; mkMerge (
            mapAttrsToList (mountPoint: x:
                let
                    group = if x.group != null then x.group else "-";
                in
                    "d ${mountPoint} ${x.permissions} ${x.owner} ${group} - -"
            ) enabled
        );

        # Mount device to mountPoint
        fileSystems = with lib; mkMerge (
            mapAttrsToList (mountPoint: x: {
                ${mountPoint} = {
                    device = x.device;
                    fsType = x.fsType;
                    options = x.options;
                };
            }) enabled
        );
    };
}
