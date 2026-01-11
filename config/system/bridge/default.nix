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
    };

    config = lib.mkIf cfg.enable {
        networking.bridges.br0.interfaces = [ cfg.interface ];
        networking.interfaces.br0.useDHCP = true;
        networking.interfaces.${cfg.interface}.useDHCP = false;
    };
}
