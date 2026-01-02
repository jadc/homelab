{ config, lib, ... }:

let
    name = "samba";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account that owns any shared files and directories";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group that owns any shared files and directories";
        };

        workgroup = mkOption {
            type = types.str;
            default = "WORKGROUP";
            description = "Workgroup name for Samba server";
        };

        shares = mkOption {
            type = types.attrsOf (types.submodule {
                options = {
                    root = mkOption {
                        type = types.str;
                        description = "Path to the directory to share";
                        example = "/data/share";
                    };

                    extraConfig = mkOption {
                        type = types.attrsOf types.str;
                        default = {};
                        description = "Extra Samba configuration options for this share";
                    };
                };
            });
            description = "Samba share configurations";
            default = {};
        };
    };

    config = lib.mkIf cfg.enable {
        # Create the user and group for Samba file ownership
        users.users.${cfg.user} = {
            isSystemUser = true;
            group = cfg.group;
        };
        users.groups.${cfg.group} = {};

        # Create share directories if they do not exist
        systemd.tmpfiles.rules = lib.mapAttrsToList (name: shareCfg:
            "d ${shareCfg.root} 0775 ${cfg.user} ${cfg.group} - -"
        ) cfg.shares;

        services.samba = {
            enable = true;
            openFirewall = true;

            settings = {
                # Configure global settings shared amongst all Samba shares
                global = {
                    workgroup = cfg.workgroup;
                    "server string" = config.networking.hostName;
                    "netbios name" = config.networking.hostName;

                    # Allow passwordless guest access
                    security = "user";
                    # Map all users to guest account (enables passwordless access)
                    "map to guest" = "bad user";
                    # Use the configured user as the guest account
                    "guest account" = cfg.user;

                    # Enforce SMB3 protocol
                    "server min protocol" = "SMB3";
                    "server max protocol" = "SMB3";

                    # Performance optimizations for Windows
                    # TCP_NODELAY: Disables Nagle's algorithm for lower latency
                    # IPTOS_LOWDELAY: Prioritizes low latency in IP layer
                    # SO_RCVBUF/SO_SNDBUF: 128KB socket buffers for better throughput
                    "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
                    # Legacy option (mostly ignored in modern Samba)
                    "read raw" = "yes";
                    # Legacy option (mostly ignored in modern Samba)
                    "write raw" = "yes";
                    # Don't strictly enforce byte-range locks for better performance
                    "strict locking" = "no";
                    # Use optimized receive for files larger than 16KB
                    "min receivefile size" = "16384";
                    # Use kernel sendfile() syscall for zero-copy transfers
                    "use sendfile" = "yes";
                    # Files larger than 16KB use asynchronous I/O
                    "aio read size" = "16384";
                    # Non-blocking I/O improves server responsiveness
                    "aio write size" = "16384";

                    # Enables Extended Attributes support for Windows metadata
                    "ea support" = "yes";
                    # Stores DOS/Windows file attributes in extended attributes
                    "store dos attributes" = "yes";
                    # Don't map Windows archive bit to Unix permissions
                    "map archive" = "no";
                    # Don't map Windows hidden bit to Unix permissions
                    "map hidden" = "no";
                    # Don't map Windows readonly bit to Unix permissions
                    "map readonly" = "no";
                    # Don't map Windows system bit to Unix permissions
                    "map system" = "no";

                    # Fruit VFS module for better macOS/Windows compatibility
                    # fruit: macOS/Windows metadata handling
                    # streams_xattr: Stores NTFS alternate data streams as extended attributes
                    # acl_xattr: Stores Windows ACLs as extended attributes
                    "vfs objects" = "fruit streams_xattr acl_xattr";
                    # Store Apple metadata in extended attributes
                    "fruit:metadata" = "stream";
                    # Identifies as MacSamba in network browsing
                    "fruit:model" = "MacSamba";
                    # Allows renaming open files (Unix behavior)
                    "fruit:posix_rename" = "yes";
                    # Don't hide Apple metadata files
                    "fruit:veto_appledouble" = "no";
                    # Don't use NFS4 ACLs
                    "fruit:nfs_aces" = "no";
                    # Clean up empty resource forks
                    "fruit:wipe_intentionally_left_blank_rfork" = "yes";
                    # Remove empty Apple metadata files
                    "fruit:delete_empty_adfiles" = "yes";

                    # Separate log file per client machine (%m = client name)
                    "log file" = "/var/log/samba/%m.log";
                    # Minimal logging (errors and warnings only)
                    "log level" = "1";
                };

            # Configure each Samba share
            } // lib.mapAttrs (shareName: shareCfg:
                {
                    path = shareCfg.root;

                    # Enable guest access (no password required)
                    "guest ok" = "yes";

                    # Read/write access
                    browseable = "yes";
                    "read only" = "no";
                    "create mask" = "0664";
                    "directory mask" = "0775";

                    # Force all files to be owned by the configured user/group
                    "force user" = cfg.user;
                    "force group" = cfg.group;
                }
                // shareCfg.extraConfig
            ) cfg.shares;
        };

        # Advertises Samba shares to Windows hosts
        services.samba-wsdd = {
            enable = true;
            workgroup = cfg.workgroup;
            discovery = true;
            openFirewall = true;
            extraOptions = [ "--verbose" ];
        };

        # Ensures firewall is open
        networking.firewall = {
            enable = true;
            allowPing = true;
        };
    };
}
