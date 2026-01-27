{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    basement = {
      url = "github:nix-prefab/nix-basement/flake-part-stories";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.basement.lib.constructFlake { inherit inputs; root = ./.; }
  {
    systems = [ "x86_64-linux" ];

    perSystem = { config, self', pkgs, system, ... }: {
      shell.packages = [
        pkgs.nodejs
        pkgs.corepack
      ];
    };
  };
}
