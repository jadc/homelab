{
    description = "jad's homelab";
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    };

    outputs = { self, nixpkgs, ... } @ inputs: {
        nixosConfigurations = let
            system = "x86_64-linux";
            inherit (self) outputs;
        in {
            jadlab = nixpkgs.lib.nixosSystem {
                inherit system;
                pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
                specialArgs = { inherit inputs outputs system; };

                modules = [
                    ./configuration.nix
                ];
            };
        };
    };
}
