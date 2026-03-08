{ config, lib, ... }:

let
    name = "caddy";
    cfg = config.homelab.service.${name};
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

                    tls = {
                        certFile = mkOption {
                            type = types.nullOr types.str;
                            default = null;
                            description = "TLS certificate for this proxy (overrides global)";
                        };

                        keyFile = mkOption {
                            type = types.nullOr types.str;
                            default = null;
                            description = "TLS private key for this proxy (overrides global)";
                        };
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
                    lib.mapAttrsToList (name: proxyCfg:
                    let
                        proxyCert = if proxyCfg.tls.certFile != null then toString proxyCfg.tls.certFile else certFile;
                        proxyKey = if proxyCfg.tls.keyFile != null then toString proxyCfg.tls.keyFile else keyFile;
                    in {
                        ${proxyCfg.domain} = {
                            extraConfig = ''
                                ${lib.optionalString (proxyCert != null && proxyKey != null)
                                "tls ${proxyCert} ${proxyKey}"}

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
