{ inputs, pkgs, ... }:

let
    prefixIPv4 = "10.66.66";
    prefixIPv6 = "fd42:42:42";
    listenPort = 443;
    externalInterface = "eno1";
in
{
    # Enable NAT
    networking = {
        nat = {
            inherit externalInterface;
            enable = true;
            internalInterfaces = [ "wg0" ];
        };
        firewall.allowedUDPPorts = [ listenPort ];
    };

    # Enable IP forwarding for routing traffic through the VPN
    boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
    };

    # Configure WireGuard interface
    networking.wireguard = {
        enable = true;
        interfaces.wg0 = {
            inherit listenPort;
            ips = [ "${prefixIPv4}.1/24" "${prefixIPv6}::1/64" ];
            privateKeyFile = "${inputs.secrets}/wireguard-private.key";

            peers = [
                {
                    publicKey = "F5dy2UCbUGr9O3Qf5VMYrg3s49qlfNL4bmYPWUWWKQo=";
                    allowedIPs = [ "${prefixIPv4}.2/32" "${prefixIPv6}::2/128" ];
                }
            ];
        };
    };
}
