{ config, lib, pkgs, ... }:

let
    name = "jellyfin";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;
    };
    config = let
        cfg = config.homelab.service.${name};
    in lib.mkIf cfg.enable {
        services.jellyfin = {
            enable = true;
            openFirewall = false;
        };

        environment.systemPackages = with pkgs; [
            jellyfin
            jellyfin-ffmpeg
            jellyfin-web
        ];
    };
}
