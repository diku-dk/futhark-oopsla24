{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/794e497348ea2019c258aeefc2c9526a0873f9be.tar.gz") {} }:
let
  futhark-original0 = import ./futhark-original/default.nix {};
  futhark-automap0 = import ./futhark-automap/default.nix {};
  futhark-original = futhark-original0.overrideAttrs (old: {
    installPhase = ''
                  mkdir -p $out/bin
                  tar xf futhark-nightly.tar.xz
                  cp futhark-nightly/bin/futhark $out/bin/futhark-original
                '';
  });
  futhark-automap= futhark-automap0.overrideAttrs (old: {
    installPhase = ''
                  mkdir -p $out/bin
                  tar xf futhark-nightly.tar.xz
                  cp futhark-nightly/bin/futhark $out/bin/futhark-automap
                '';
  });
  benchmarks = pkgs.copyPathToStore ./benchmarks;
  image = pkgs.dockerTools.pullImage {
    imageName = "archlinux";
    imageDigest = "sha256:4d4821711ba77904458da94ad3db7de44184c6945eb684f96438fe7778b2420f";
    sha256 = "xh4pORTdjryCMkEJdmjZUBmIVldaQ7EmtjLhKi5xe9M=";
    finalImageName = "archlinux";
    finalImageTag = "base-devel";
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "futhark-oopsla24";
  tag = "latest";
  fromImage = image;
  contents = with pkgs; 
    [futhark-original
     futhark-automap
     benchmarks
     coreutils
     bash
     findutils
     vim
     scc
     hyperfine
     gnuplot
    ];

  config = {
    Cmd = [ "/bin/bash"];
    WorkingDir = "${benchmarks}";
  };

}
