{ pkgs, ... }:

{
    services.jellyfin.enable = true;
    environment.systemPackages = [
        pkgs.jellyfin
        pkgs.jellyfin-web
        pkgs.jellyfin-ffmpeg
    ];

    # Add to reverse proxy
    # services.caddy.virtualHosts."todo".extraConfig = ''reverse_proxy 127.0.0.1:8096'';
}
