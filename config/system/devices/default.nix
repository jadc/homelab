{ config, lib, pkgs, ... }:

let
    name = "devices";
    cfg = config.homelab.system.${name};
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

                mergePoint = mkOption {
                    type = types.nullOr types.str;
                    description = "Path where this device should be merged with others using mergerfs";
                    default = null;
                };
            };
        });
    };

    config = let
        drives = lib.filterAttrs (name: x: x.enable) cfg;
        mergePointGroups = lib.groupBy (x: x.mergePoint) (lib.filter (x: x.mergePoint != null) (lib.attrValues drives));
    in lib.mkMerge [
        {
            # Enable TRIM for SSDs
            services.fstrim.enable = true;

            # Create mountPoint directory for each device
            systemd.tmpfiles.rules = with lib;
                mapAttrsToList (name: x:
                    "d ${x.mountPoint} 0755 root - - -"
                ) drives;

            # Mount each device to its mountPoint
            fileSystems = with lib; mkMerge (
                mapAttrsToList (name: x: {
                    ${x.mountPoint} = {
                        device = x.device;
                        fsType = x.fsType;
                        options = x.options;
                    };
                }) drives
            );
        }
        (lib.mkIf (mergePointGroups != {}) {
            environment.systemPackages = [ pkgs.mergerfs ];

            # Create each mergePoint directory
            systemd.tmpfiles.rules = lib.mapAttrsToList (mergePoint: devices:
                "d ${mergePoint} 0755 root - - -"
            ) mergePointGroups;

            # Mount each merged device to its mergePoint
            fileSystems = lib.mkMerge (
                lib.mapAttrsToList (mergePoint: devices: {
                    ${mergePoint} = {
                        device = lib.concatStringsSep ":" (map (x: x.mountPoint) devices);
                        fsType = "fuse.mergerfs";
                        options = [
                            "defaults"
                            "allow_other"
                            "cache.files=partial"
                            "category.create=mfs"
                            "dropcacheonclose=true"
                            "ignorepponrename=true"
                            "minfreespace=10G"
                            "moveonenospc=true"
                            "use_ino"
                        ];
                    };
                }) mergePointGroups
            );
        })
    ];
}
