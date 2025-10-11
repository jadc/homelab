{ config, inputs, ... }:

{
    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";

            superuser = {
                hashedPasswordFile = "${inputs.secrets}/passwd.hash";
            };

            devices = {
                data = {
                    mountPoint = "/data";
                    device = "/dev/disk/by-uuid/5db1a674-6c38-4956-a7ca-ae7dce2c7772";
                    fsType = "xfs";
                };
            };
        };

        service = {
            wireguard = let cfg = config.homelab.service.wireguard; in {
                interface = "eno1";
                ipv4Prefix = "10.66.66";
                ipv6Prefix = "fd42:42:42";
                peers = [
                    {
                        publicKey = "F5dy2UCbUGr9O3Qf5VMYrg3s49qlfNL4bmYPWUWWKQo=";
                        allowedIPs = [ "${cfg.ipv4Prefix}.2/32" "${cfg.ipv6Prefix}::2/128" ];
                    }
                ];
                port = 443;
                privateKeyFile = "${inputs.secrets}/wireguard-private.key";
            };

            caddy = {
                enable = true;
                tls.certFile = toString ./config/service/caddy/cert.pem;
                tls.keyFile = "${inputs.secrets}/ssl-private.key";
            };

            jellyfin = {
                enable = true;
                group = "media";
                port = 8096;
            };
            caddy.proxies.jellyfin = {
                domain = "media.jad.red";
                port = 8096;
            };

            servarr = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/media";
                group = "media";
                sonarr.apiKeyFile = "${inputs.secrets}/sonarr.key";
                radarr.apiKeyFile = "${inputs.secrets}/radarr.key";
            };

            transmission = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/torrents";
                user = "torrent";
                group = "media";
            };

            syncthing = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/sync";
            };

            filebrowser = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/sync";
                group = "sync";
                port = 8099;
            };
            caddy.proxies.filebrowser = {
                domain = "files.jad.red";
                port = 8099;
            };
        };
    };
}

