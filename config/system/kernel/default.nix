{ config, pkgs, lib, ... }:

let
    name = "kernel";
    self = config.homelab.system.${name};
in
{
    options.homelab.system.${name} = with lib; {
        enable = mkEnableOption name;

        build = mkOption {
            type = types.raw;
            default = pkgs.linuxPackages_latest;
        };

        flags = {
            quiet = mkOption {
                type = types.bool;
                default = false;
            };

            performance = mkOption {
                type = types.bool;
                default = false;
            };

            intel = mkOption {
                type = types.bool;
                default = false;
            };

            nvidia = mkOption {
                type = types.bool;
                default = false;
            };
        };
    };

    config = with lib; mkIf self.enable {
        hardware.enableAllFirmware = true;
        hardware.enableRedistributableFirmware = true;

        boot = {
            kernelPackages = self.build;
            kernelParams =
                optionals self.flags.quiet [
                    # Report Linux to ACPI for better hardware compatibility
                    "acpi_osi=Linux"
                    # Only show errors and critical messages in kernel log
                    "loglevel=3"
                    # Suppress most boot messages
                    "quiet"
                    # Only show systemd status if boot takes too long
                    "rd.systemd.show_status=auto"
                    # Reduce udev logging to errors only
                    "rd.udev.log_level=3"
                ] ++ optionals self.flags.performance [
                    # Disable hardware watchdog timer to save CPU cycles
                    "nowatchdog"
                    # Disable machine check exception logging for performance
                    "nomce"
                    # Disable CPU vulnerability mitigations for maximum speed
                    "mitigations=off"
                    # Trust CPU's random number generator to speed up entropy gathering
                    "random.trust_cpu=on"
                    # Skip filesystem checks at boot
                    "fsck.mode=skip"
                    # Disable staggered spin-up for SATA drives (faster boot)
                    "libahci.ignore_sss=1"
                    # Disable audit subsystem to reduce overhead
                    "audit=0"
                    # Disable transparent hugepages defrag to reduce latency spikes
                    "transparent_hugepage=madvise"
                    # Disable NUMA balancing for better performance on single-node systems
                    "numa_balancing=disable"
                ] ++ optionals self.flags.intel [
                    # Enable kernel mode-setting for Intel graphics (required for hardware transcoding)
                    "i915.modeset=1"
                    # Enable GuC (Graphics microController) firmware for better GPU scheduling
                    "i915.enable_guc=3"
                ] ++ optionals (!self.flags.intel) [
                    # Disable Intel graphics
                    "i915.modeset=0"
                ] ++ optionals (!self.flags.nvidia) [
                    # Disable NVIDIA GPU
                    "nouveau.modeset=0"
                ];

            # Blacklist GPU drivers when their respective flags are disabled
            blacklistedKernelModules =
                optionals (!self.flags.intel) [
                    "i915"           # Intel integrated graphics driver
                    "xe"             # Intel Xe graphics driver (newer GPUs)
                ] ++ optionals (!self.flags.nvidia) [
                    "nouveau"        # Open-source NVIDIA driver
                    "nvidia"         # Proprietary NVIDIA driver
                    "nvidia_drm"     # NVIDIA DRM kernel module
                    "nvidia_modeset" # NVIDIA modesetting module
                    "nvidia_uvm"     # NVIDIA Unified Memory module
                ];
        };

        # Remove NVIDIA PCI devices from the system when disabled
        services.udev.extraRules = mkIf (!self.flags.nvidia) ''
            # Remove NVIDIA USB xHCI Host Controller devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
            # Remove NVIDIA USB Type-C UCSI devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
            # Remove NVIDIA Audio devices, if present
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
            # Remove NVIDIA VGA/3D controller devices
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
        '';

        services.xserver.videoDrivers = mkIf self.flags.intel [ "modesetting" ];

        hardware.graphics = mkIf self.flags.intel {
            enable = true;
            extraPackages = with pkgs; [
                # Required for modern Intel GPUs (Xe iGPU and ARC)
                intel-media-driver            # VA-API (iHD) userspace
                vpl-gpu-rt                    # oneVPL (QSV) runtime
                intel-compute-runtime  # OpenCL (NEO) + Level Zero for Arc/Xe
            ];
        };

        environment.sessionVariables = mkIf self.flags.intel {
            LIBVA_DRIVER_NAME = "iHD";     # Prefer the modern iHD backend
        };

        hardware.nvidia = mkIf self.flags.nvidia {
            modesetting.enable = true;

            # Use open drivers (for modern cards)
            open = true;

            # Use beta channel
            package = config.boot.kernelPackages.nvidiaPackages.beta;
        };
    };
}