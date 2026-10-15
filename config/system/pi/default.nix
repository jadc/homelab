{ inputs, ... }:

{
    imports = [ inputs.pi.nixosModules.default ];
}
