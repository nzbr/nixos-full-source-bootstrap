{
  all = [ «derivation /nix/store/3ab...9m4-example.drv» ];
  args = [ "-c" "echo hello world > $out" ];
  builder = "/nix/store/aqb...qsy-bash-interactive-5.2p37/bin/bash";
  drvAttrs = {
    args = [ "-c" "echo hello world > $out" ];
    builder = "/nix/store/aqb...qsy-bash-interactive-5.2p37/bin/bash";
    name = "example";
    system = "x86_64-linux";
  };
  drvPath = "/nix/store/3ab…9m4-example.drv";
  name = "example";
  out = «derivation /nix/store/3ab...9m4-example.drv»;
  outPath = "/nix/store/n1x...s2k-example";
  outputName = "out";
  system = "x86_64-linux";
  type = "derivation";
}
