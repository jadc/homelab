{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

        secrets = {
            url = "git+ssh://git@github.com/jadc/homelab-secrets";
            flake = false;
        };
    };

    outputs = { self, nixpkgs, ... } @ inputs: let
        hostname = "homelab";
        system = "x86_64-linux";
    in {
        nixosConfigurations = let inherit (self) outputs; in {
            ${hostname} = nixpkgs.lib.nixosSystem {
                inherit system;
                pkgs = import nixpkgs {
                    inherit system;
                    config.allowUnfree = true;
                };
                specialArgs = {
                    inherit inputs outputs system;
                };

                modules = [
                    { networking.hostName = hostname; }
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
