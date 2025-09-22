{ config, inputs, ... }:

{
    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";

            devices = {
                "/data/media" = {
                    device = "/dev/disk/by-uuid/d91b87c6-61f9-4901-99ee-efde2b36bbeb";
                    fsType = "xfs";
                    group = "media";
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
        };
    };
}
