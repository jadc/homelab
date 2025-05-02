{ inputs, pkgs, ... }:

let
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

    # Copy private key from secrets
    environment.etc."wireguard-private.key".source = "${inputs.secrets}/wireguard-private.key";

    networking.wireguard = {
        enable = true;
        interfaces.wg0 = {
            ips = [ "10.66.66.1/24" "fd42:42:42::1/64" ];
            listenPort = port;

            postSetup = ''
                ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
                '';
            postShutdown = ''
                ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o eth0 -j MASQUERADE
                '';

            privateKeyFile = "/etc/wireguard-private.key";

            peers = [
                # Laptop
                {
                    publicKey = "H0Ux2fL64k6V9rG/BEegP0hNpye/gYNs6R1o/dIXNSg=";
                    allowedIPs = [ "10.66.66.2/32" "fd42:42:42::2/128" ];
                }
                # iPhone
                {
                    publicKey = "F5dy2UCbUGr9O3Qf5VMYrg3s49qlfNL4bmYPWUWWKQo=";
                    allowedIPs = [ "10.66.66.3/32" "fd42:42:42::3/128" ];
                }
            ];
        };
    };
}
