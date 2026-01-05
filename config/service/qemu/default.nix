{ config, lib, pkgs, ... }:

let
    name = "qemu";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;
    };

    config = lib.mkIf cfg.enable {
        programs.virt-manager.enable = true;
        virtualisation.spiceUSBRedirection.enable = true;
        virtualisation.libvirtd = {
            enable = true;
            qemu = {
                package = pkgs.qemu_kvm;
                runAsRoot = true;
                swtpm.enable = true;
                ovmf = {
                    enable = true;
                    packages = [(pkgs.OVMF.override {
                        secureBoot = true;
                        tpmSupport = true;
                    }).fd];
                };
            };
        };
    };
}
