{ config, lib, ... }:

let
    name = "wireguard";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        interface      = mkOption { type = types.str; };
        ipv4Prefix     = mkOption { type = types.str; };
        ipv6Prefix     = mkOption { type = types.str; };
        port           = mkOption { type = types.int; };
        privateKeyFile = mkOption { type = types.str; };
        peers          = mkOption {
            type = with types; listOf (submodule {
                options = {
                    publicKey  = mkOption { type = types.singleLineStr; };
                    allowedIPs = mkOption { type = with types; listOf str; };
                };
            });
        };
    };

    config = {
        # Configure WireGuard interface
        networking.wireguard = {
            enable = true;
            interfaces.wg0 = {
                ips = [ "${cfg.ipv4Prefix}.1/24" "${cfg.ipv6Prefix}::1/64" ];
                listenPort = cfg.port;
                peers = cfg.peers;
                privateKeyFile = cfg.privateKeyFile;
            };
        };

        # Enable NAT
        networking = {
            nat = {
                enable = true;
                externalInterface = cfg.interface;
                internalInterfaces = [ "wg0" ];
            };
            firewall.allowedUDPPorts = [ cfg.port ];
        };

        # Enable IP forwarding for routing traffic through the VPN
        boot.kernel.sysctl = {
            "net.ipv4.ip_forward" = 1;
            "net.ipv6.conf.all.forwarding" = 1;
        };
    };
}
