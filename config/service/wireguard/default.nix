{ inputs, pkgs, ... }:

let
    prefixIPv4 = "10.66.66.";
    prefixIPv6 = "fd42:42:42::";
    port = 123;

in
{
    # enable NAT
    networking = {
        nat = {
            enable = true;
            externalInterface = "eth0";
            internalInterfaces = [ "wg0" ];
        };
        firewall.allowedUDPPorts = [ port ];
    };

    networking.wireguard = {
        enable = true;
        interfaces.wg0 = {
            ips = [ (prefixIPv4+"1/24") (prefixIPv6+"1/64") ];
            listenPort = port;

            postSetup    = "${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${prefixIPv4}0/24 -o eth0 -j MASQUERADE";
            postShutdown = "${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${prefixIPv4}0/24 -o eth0 -j MASQUERADE";

            privateKeyFile = "${inputs.secrets}/wireguard-private.key";

            peers = [
                # Laptop
                {
                    publicKey = "H0Ux2fL64k6V9rG/BEegP0hNpye/gYNs6R1o/dIXNSg=";
                    allowedIPs = [ (prefixIPv4+"2/32") (prefixIPv6+"2/128") ];
                }
                # iPhone
                {
                    publicKey = "F5dy2UCbUGr9O3Qf5VMYrg3s49qlfNL4bmYPWUWWKQo=";
                    allowedIPs = [ (prefixIPv4+"3/32") (prefixIPv6+"3/128") ];
                }
            ];
        };
    };
}
