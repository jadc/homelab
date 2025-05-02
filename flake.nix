{
    description = "jad's homelab";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

        /*
        secrets = {
            url = "git+ssh://git@github.com/jadc/homelab-secrets";
            flake = false;
        };
        */
    };

    outputs = { self, nixpkgs, ... } @ inputs: {
        nixosConfigurations = let
            hostname = "jadlab";
            system = "x86_64-linux";
            inherit (self) outputs;
        in {
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
                    ./config
                    ./configuration.nix
                ];
            };
        };
    };
}
