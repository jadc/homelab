{ config, lib, ... }:

let
    name = "caddy";
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        tls = {
            certFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Path to TLS certificate";
            };

            keyFile = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Path to TLS private key";
            };
        };

        proxies = mkOption {
            type = types.attrsOf (types.submodule {
                options = {
                    domain = mkOption {
                        type = types.str;
                        description = "Domain for this service";
                        example = "service.example.com";
                    };

                    port = mkOption {
                        type = types.port;
                        description = "Local port of the service";
                        example = 8080;
                    };

                    extraConfig = mkOption {
                        type = types.lines;
                        default = ''
                            header_up Host {host}
                            header_up X-Real-IP {remote_host}
                            header_up X-Forwarded-For {remote_host}
                            header_up X-Forwarded-Proto {scheme}
                            header_up X-Forwarded-Host {host}
                        '';
                        description = "Configuration for this proxy";
                    };
                };
            });
            description = "Reverse proxy configurations";
            default = {};
        };
    };

    config = let
        cfg = config.homelab.service.${name};
    in lib.mkIf cfg.enable {
        services.caddy = {
            enable = true;

            virtualHosts = lib.mkMerge (
                lib.mapAttrsToList (name: proxyCfg: {
                    ${proxyCfg.domain} = {
                        extraConfig = ''
                            ${lib.optionalString (cfg.tls.certFile != null && cfg.tls.keyFile != null)
                                "tls ${cfg.tls.certFile} ${cfg.tls.keyFile}"}
                            reverse_proxy 127.0.0.1:${toString proxyCfg.port} {
                                ${proxyCfg.extraConfig}
                            }
                        '';
                    };
                }) cfg.proxies
            );
        };

        networking.firewall.allowedTCPPorts = [ 80 443 ];
    };
}
