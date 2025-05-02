{ pkgs, ... }:

{
    # Nix configuration
    nix.settings = {
        auto-optimise-store = pkgs.stdenv.isLinux;

        # Enable flakes
        experimental-features = [ "nix-command" "flakes" ];
    };

    # Fix shutdown hang
    hardware.enableAllFirmware = true;

    # Do not need to update
    system.stateVersion = "24.05";
}
