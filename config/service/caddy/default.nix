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

                    reverseProxyConfig = mkOption {
                        type = types.lines;
                        default = "";
                        description = "Extra configuration inside the reverse_proxy block";
                    };

                    extraConfig = mkOption {
                        type = types.lines;
                        default = "";
                        description = "Extra configuration for this virtual host (outside reverse_proxy)";
                    };
                };
            });
            description = "Reverse proxy configurations";
            default = {};
        };
    };

    config = let
        cfg = config.homelab.service.${name};
        certFile = if cfg.tls.certFile != null then toString cfg.tls.certFile else null;
        keyFile = if cfg.tls.keyFile != null then toString cfg.tls.keyFile else null;
    in lib.mkIf cfg.enable {
            services.caddy = {
                enable = true;

                # Disable HTTP/3 (QUIC) to disable UDP 443
                globalConfig = ''
                    servers {
                        protocols h1 h2
                    }
                '';

                virtualHosts = lib.mkMerge (
                    lib.mapAttrsToList (name: proxyCfg: {
                        ${proxyCfg.domain} = {
                            extraConfig = ''
                                ${lib.optionalString (certFile != null && keyFile != null)
                                "tls ${certFile} ${keyFile}"}

                                reverse_proxy localhost:${toString proxyCfg.port} {
                                    ${proxyCfg.reverseProxyConfig}
                                }

                                ${proxyCfg.extraConfig}
                            '';
                        };
                    }) cfg.proxies
                );
            };

            networking.firewall.allowedTCPPorts = [ 80 443 ];
        };
}
