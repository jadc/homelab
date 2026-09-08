{ config, lib, ... }:

let
    name = "caddy";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which Caddy runs";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which Caddy runs";
        };

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
        certPath = "/etc/caddy/cert.pem";
        keyPath = "/etc/caddy/private.key";
    in lib.mkIf cfg.enable {
            environment.etc = lib.mkMerge ([
                (lib.mkIf (cfg.tls.certFile != null) {
                    "caddy/cert.pem".source = cfg.tls.certFile;
                })
                (lib.mkIf (cfg.tls.keyFile != null) {
                    "caddy/private.key" = {
                        source = cfg.tls.keyFile;
                        mode = "0400";
                        user = cfg.user;
                        group = cfg.group;
                    };
                })
            ] ++ lib.flatten (lib.mapAttrsToList (name: proxyCfg: [
                (lib.mkIf (proxyCfg.tls.certFile != null) {
                    "caddy/${name}.pem".source = proxyCfg.tls.certFile;
                })
                (lib.mkIf (proxyCfg.tls.keyFile != null) {
                    "caddy/${name}.key" = {
                        source = proxyCfg.tls.keyFile;
                        mode = "0400";
                        user = cfg.user;
                        group = cfg.group;
                    };
                })
            ]) cfg.proxies));

            services.caddy = {
                enable = true;
                user = cfg.user;
                group = cfg.group;

                # Disable HTTP/3 (QUIC) to disable UDP 443
                globalConfig = ''
                    servers {
                        protocols h1 h2
                    }
                '';

                virtualHosts = lib.mkMerge (
                    lib.mapAttrsToList (name: proxyCfg:
                    let
                        proxyCert = if proxyCfg.tls.certFile != null then "/etc/caddy/${name}.pem" else certPath;
                        proxyKey = if proxyCfg.tls.keyFile != null then "/etc/caddy/${name}.key" else keyPath;
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
