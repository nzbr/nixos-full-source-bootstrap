let
  pkgs = import <nixpkgs> { system = "x86_64-linux"; };
in
derivation {
  name = "example";
  builder = "${pkgs.bash}/bin/bash";
  args = [ "-c" "echo hello world > $out" ];
  system = "x86_64-linux";
}
