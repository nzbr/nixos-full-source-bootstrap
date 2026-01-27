(import <nixpkgs/nixos> {
  configuration = builtins.toFile "configuration.nix" ''
    { ... }:
    {
      imports = [ <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix> ];

      nixpkgs.buildPlatform = "x86_64-linux";
      nixpkgs.hostPlatform = "aarch64-linux";
    }
  '';
}).config.system.build.isoImage
