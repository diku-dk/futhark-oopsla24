{ pkgs ? import (fetchTarball
  "https://github.com/NixOS/nixpkgs/archive/794e497348ea2019c258aeefc2c9526a0873f9be.tar.gz")
  { } }:
let
  futhark-original0 = import ./futhark-original/default.nix { };
  futhark-automap0 = import ./futhark-automap/default.nix { };
  futhark-original = futhark-original0.overrideAttrs (old: {
    installPhase = ''
      mkdir -p $out/bin
      tar xf futhark-nightly.tar.xz
      cp futhark-nightly/bin/futhark $out/bin/futhark-original
    '';
  });
  futhark-automap = futhark-automap0.overrideAttrs (old: {
    installPhase = ''
      mkdir -p $out/bin
      tar xf futhark-nightly.tar.xz
      cp futhark-nightly/bin/futhark $out/bin/futhark-automap
    '';
  });
  artifact = pkgs.copyPathToStore ./artifact;
in pkgs.dockerTools.buildImage {
  name = "futhark-oopsla24";
  tag = "latest";
  created = "now";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = with pkgs; [
      futhark-original
      futhark-automap

      # Dependencies
      coreutils
      gnugrep
      gnused
      gnumake
      gawk
      bash
      findutils
      nano
      scc
      hyperfine
      gnuplot
      bc
    ];
  };

  runAsRoot = ''
    mkdir -p /tmp
    chmod 777 /tmp
  '';

  config = {
    Cmd = [ "/bin/bash" ];
    WorkingDir = "${artifact}";
  };

}
