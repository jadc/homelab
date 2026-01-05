{ config, inputs, ... }:

{
    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";

            kernel = {
                enable = true;
                flags = {
                    intel = true;
                    nvidia = false;
                    performance = true;
                    quiet = true;

                    # Pass through NVIDIA GPU
                    vfio = [ "10de:2208" "10de:1aef" ];
                };
            };

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

            hd-idle = {
                enable = true;
                spindownTime = 10 * 60;
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
                group = config.homelab.service.servarr.group;
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
                group = config.homelab.service.servarr.group;
            };

            syncthing = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/sync";
                group = "sync";
            };

            filebrowser = {
                enable = false;
                root = "${config.homelab.system.devices.data.mountPoint}/sync";
                group = config.homelab.service.syncthing.group;
                port = 8099;
            };

            immich = {
                enable = true;
                root = "${config.homelab.system.devices.data.mountPoint}/gallery";
                group = config.homelab.service.syncthing.group;
            };

            samba = {
                enable = true;
                group = config.homelab.service.syncthing.group;

                shares = {
                    shared = {
                        root = "${config.homelab.system.devices.data.mountPoint}/shared";
                    };
                    vault = {
                        root = "${config.homelab.system.devices.data.mountPoint}/sync/vault";
                    };
                };
            };

            qemu = {
                enable = true;
            }
        };
    };
}
