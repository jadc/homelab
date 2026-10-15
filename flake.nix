{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

        pi = {
            url = "github:jadc/pi";
        };

        secrets = {
            url = "git+ssh://git@github.com/jadc/homelab-secrets";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, ... } @ inputs: let
        hostname = "chieftain";
        system = "x86_64-linux";
    in {
        nixosConfigurations = let inherit (self) outputs; in {
            ${hostname} = nixpkgs.lib.nixosSystem {
                specialArgs = {
                    inherit inputs outputs;
                };

                modules = [
                    {
                        networking.hostName = hostname;
                        nixpkgs.hostPlatform = system;
                        nixpkgs.config.allowUnfree = true;
                    }
                    ./configuration.nix
                    ./hardware-configuration.nix
                    ./config
                ];
            };
        };

        # Allows testing the configuration in a VM
        apps.${system} = rec {
            default = test;
            test = {
                type = "app";
                program = "${self.nixosConfigurations.${hostname}.config.system.build.vm}/bin/run-${hostname}-vm";
            };
        };
    };
}
