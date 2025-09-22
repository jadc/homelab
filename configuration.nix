{ config, inputs, ... }:

{
    imports = [
        # System
        ./config/system/locale
        ./config/system/misc
        ./config/system/tlp
        ./config/system/tools
        ./config/system/user

        # Services
        ./config/service/ssh
        ./config/service/wireguard
    ];

    homelab = {
        system = {
            timeZone = "America/Edmonton";
            locale = "en_CA.UTF-8";

            devices = [
                {
                    device = "/dev/disk/by-uuid/d91b87c6-61f9-4901-99ee-efde2b36bbeb";
                    mountPoint = "/data/media";
                    fsType = "xfs";
                    group = "media";
                }
            ];
        };

        service = {
            wireguard = {
                interface = "eno1";
                ipv4Prefix = "10.66.66";
                ipv6Prefix = "fd42:42:42";
                peers = let
                    ipv4 = config.homelab.service.wireguard.ipv4Prefix;
                    ipv6 = config.homelab.service.wireguard.ipv6Prefix;
                in [
                    {
                        publicKey = "F5dy2UCbUGr9O3Qf5VMYrg3s49qlfNL4bmYPWUWWKQo=";
                        allowedIPs = [ "${ipv4}.2/32" "${ipv6}::2/128" ];
                    }
                ];
                port = 443;
                privateKeyFile = "${inputs.secrets}/wireguard-private.key";
            };
        };
    };
}
