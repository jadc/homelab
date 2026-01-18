{ config, lib, pkgs, ... }:

let
    name = "wol";
    cfg = config.homelab.service.${name};

    wolListener = pkgs.writeScript "wol-listener" ''
        #!${pkgs.python3}/bin/python3

        import socket
        import subprocess
        import sys

        PORT = ${toString cfg.port}
        COMMAND = """${cfg.command}"""

        def is_wol_packet(data):
            if len(data) < 102:
                return False, None
            # Check for 6 bytes of 0xFF
            if data[:6] != b'\xff' * 6:
                return False, None
            # Extract MAC address (next 6 bytes, repeated 16 times)
            mac = data[6:12]
            # Verify MAC is repeated 16 times
            for i in range(16):
                if data[6 + i*6:12 + i*6] != mac:
                    return False, None
            return True, mac.hex()

        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.bind(("", PORT))
        print(f"Listening for WOL packets on port {PORT}...")
        sys.stdout.flush()

        while True:
            data, addr = sock.recvfrom(1024)
            is_wol, target_mac = is_wol_packet(data)
            if is_wol:
                print(f"WOL packet received from {addr} for MAC {target_mac}, executing command...")
                sys.stdout.flush()
                subprocess.run(COMMAND, shell=True)
    '';
in
{
    options.homelab.service.${name} = with lib; {
        enable = mkEnableOption "Wake-On-LAN listener";

        command = mkOption {
            type = types.str;
            description = "Command to execute when a WOL packet is received";
        };

        port = mkOption {
            type = types.int;
            default = 9;
            description = "UDP port to listen for WOL packets";
        };
    };

    config = lib.mkIf cfg.enable {
        networking.firewall.allowedUDPPorts = [ cfg.port ];

        systemd.services.wol-listener = {
            description = "Wake-On-LAN Listener";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];

            serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = 5;
                ExecStart = "${wolListener}";
            };
        };
    };
}
