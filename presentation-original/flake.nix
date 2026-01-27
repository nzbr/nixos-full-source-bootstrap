{
  inputs = {
    # nixpkgs.url = "/home/nzbr/Bachelorarbeit/nixpkgs-bootstrap";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    basement = {
      url = "github:nix-prefab/nix-basement/flake-part-stories";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not override nixpkgs input here or the caching breaks
    copperflame.url = "github:nzbr/copperflame";
  };

  nixConfig = {
    extra-substituters = [
      "https://nzbr-nix-cache.s3.eu-central-1.wasabisys.com"
    ];
    extra-trusted-public-keys = [
      "nzbr-nix-cache.s3.eu-central-1.wasabisys.com:3BzCCe4Frvvwamd5wibtMAcEKwbVs4y2xKUR2vQ8gIo="
    ];
  };

  outputs = inputs: inputs.basement.lib.constructFlake { inherit inputs; root = ./.; }
  {
    systems = [ "x86_64-linux" ];

    perSystem = { config, self', pkgs, system, ... }: {
      shell = {
        packages = [
          pkgs.nodejs
          pkgs.corepack
        ];
        hook = ''
          mkdir -p generated
          ln -sfT ${self'.packages.fonts} generated/fonts
        '';
      };

      packages = {
        fonts = pkgs.stdenvNoCC.mkDerivation {
          name = "thesis-fonts";

          buildCommand = ''
            mkdir -p $out

            ln -s ${inputs.copperflame.packages.${system}.copperflame-mono.unpatched}/share/fonts/truetype/*.ttf $out/
          '';
        };
      };
    };
  };
}
