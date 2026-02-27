{ config, lib, pkgs, ... }:

let
    name = "vm";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        hugepages = {
            enable = mkEnableOption "dynamic hugepage allocation for a VM";

            size = mkOption {
                type = types.int;
                default = 0;
                description = "Number of 2MB hugepages to allocate dynamically when the VM starts";
            };

            guest = mkOption {
                type = types.str;
                description = "Name of the libvirt guest to allocate hugepages for";
            };
        };
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
            spice
            spice-gtk
            spice-protocol
            win-spice
            virtio-win
        ];

        services.spice-vdagentd.enable = true;
        virtualisation.spiceUSBRedirection.enable = true;
        virtualisation.libvirtd = {
            enable = true;
            qemu = {
                package = pkgs.qemu_kvm;
                runAsRoot = true;
                swtpm.enable = true;
            };
        };

        # Allow libvirt to lock memory for hugepages
        systemd.services.libvirtd.serviceConfig.LimitMEMLOCK = "infinity";

        # Dynamically allocate/free hugepages on VM start/stop
        virtualisation.libvirtd.hooks.qemu = lib.mkIf cfg.hugepages.enable {
            hugepages = pkgs.writeShellScript "qemu-hugepages-hook" ''
                GUEST="$1"
                OPERATION="$2"
                SUB_OPERATION="$3"
                HUGEPAGES=${toString cfg.hugepages.size}

                [ "$GUEST" != "${cfg.hugepages.guest}" ] && exit 0

                if [ "$OPERATION" = "prepare" ] && [ "$SUB_OPERATION" = "begin" ]; then
                    sync
                    echo 3 > /proc/sys/vm/drop_caches
                    echo 1 > /proc/sys/vm/compact_memory
                    echo "$HUGEPAGES" > /proc/sys/vm/nr_hugepages

                    ALLOCATED=$(cat /proc/sys/vm/nr_hugepages)
                    if [ "$ALLOCATED" -lt "$HUGEPAGES" ]; then
                        echo "Failed to allocate hugepages: got $ALLOCATED, wanted $HUGEPAGES" >&2
                        echo 0 > /proc/sys/vm/nr_hugepages
                        exit 1
                    fi
                elif [ "$OPERATION" = "release" ] && [ "$SUB_OPERATION" = "end" ]; then
                    echo 0 > /proc/sys/vm/nr_hugepages
                fi
            '';
        };

        # Start VM when receiving WoL packet
        homelab.service.wol = {
            enable = true;
            command = "${pkgs.libvirt}/bin/virsh start win11";
        };
    };
}
