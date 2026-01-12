{ config, lib, pkgs, ... }:

let
    name = "vm";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;
    };

    config = lib.mkIf cfg.enable {
        environment.systemPackages = with pkgs; [
            spice
            spice-gtk
            spice-protocol
            win-spice
            win-virtio
        ];

        services.spice-vdagentd.enable = true;
        virtualisation.spiceUSBRedirection.enable = true;
        virtualisation.libvirtd = {
            enable = true;
            qemu = {
                package = pkgs.qemu_kvm;
                runAsRoot = true;
                swtpm.enable = true;
                ovmf = {
                    enable = true;
                    packages = [(pkgs.OVMFFull.override {
                        secureBoot = true;
                        tpmSupport = true;
                    }).fd];
                };
            };
        };
    };
}
