{ pkgs, ... }:

let
    fcm = pkgs.writers.writePython3Bin "fcm" {} (builtins.readFile ./fcm.py);
in
{
    environment.systemPackages = [ fcm ];
}
