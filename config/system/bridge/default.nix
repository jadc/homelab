{ config, lib, ... }:

let
    name = "bridge";
    cfg = config.homelab.system.${name};
in
{
    options.homelab.system.${name} = with lib; {
        enable = mkEnableOption "bridged networking";
        interface = mkOption {
            type = types.str;
            description = "Physical interface to bridge";
        };
        macAddress = mkOption {
            type = types.str;
            description = "MAC address for the bridge to use";
        };
    };

    config = lib.mkIf cfg.enable {
        networking = {
            useDHCP = false;

            # Enable and use bridge
            bridges.br0.interfaces = [ cfg.interface ];
            interfaces.br0.useDHCP = true;
            interfaces.br0.macAddress = cfg.macAddress;
            firewall.trustedInterfaces = [ "br0" "virbr0" ];

            # Disable interfaces that are now in the bridge
            interfaces.${cfg.interface}.useDHCP = false;
        };
    };
}
