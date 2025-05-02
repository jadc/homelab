{ pkgs, ... }:

{
    # Nix configuration
    nix.settings = {
        auto-optimise-store = pkgs.stdenv.isLinux;

        # Enable flakes
        experimental-features = [ "nix-command" "flakes" ];
    };

    # Use systemd-boot as a bootloader
    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        timeout = 0;
    };

    # Fix shutdown hang
    hardware.enableAllFirmware = true;

    # Do not need to update
    system.stateVersion = "24.05";
}
