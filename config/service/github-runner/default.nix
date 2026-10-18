{ config, lib, pkgs, ... }:

let
    name = "github-runner";
    cfg = config.homelab.service.${name};
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption name;

        url = mkOption {
            type = types.str;
            description = "Repository or organisation URL to register the runner with";
        };

        tokenFile = mkOption {
            type = types.str;
            description = "Path to a file containing a fine-grained PAT with read/write access to self-hosted runners administration (organisation-level for an organisation URL)";
        };

        count = mkOption {
            type = types.ints.positive;
            default = 1;
            description = "Number of runners, i.e. how many jobs can run concurrently";
        };

        user = mkOption {
            type = types.str;
            default = name;
            description = "User account under which the runners run";
        };

        group = mkOption {
            type = types.str;
            default = name;
            description = "Group under which the runners run";
        };
    };

    config = lib.mkIf cfg.enable {
        homelab.service.docker.enable = true;

        users = {
            users.${cfg.user} = {
                isSystemUser = true;
                group = cfg.group;
                extraGroups = [ "docker" ];
            };
            groups.${cfg.group} = {};
        };

        services.github-runners.${name} = {
            enable = true;
            inherit (cfg) url tokenFile count user group;
            name = config.networking.hostName;

            # Re-register cleanly when the state directory is wiped
            replace = true;

            serviceOverrides = {
                Restart = lib.mkForce "on-failure";
                RestartSec = 30;

                # A private user namespace hides the docker group, blocking socket access
                PrivateUsers = false;

                # The runner reads /proc/1/cgroup before starting job/service containers;
                # the module's default ProtectProc = "invisible" hides PID 1 from this user
                ProtectProc = lib.mkForce "default";
            };

            # Tools that GitHub-hosted ubuntu runners provide and common actions expect
            extraPackages = with pkgs; [
                curl
                docker
                findutils
                gawk
                gnugrep
                gnused
                jq
                which
                xz
                zstd

                # Toolchain management; nixpkgs' rustup patches downloaded toolchains for NixOS
                cmake
                gcc
                gnumake
                pkg-config
                rustup
            ];
        };
    };
}
