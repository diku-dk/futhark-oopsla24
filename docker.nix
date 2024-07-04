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
  artifact = pkgs.copyPathToStore ./artifact;
  image = pkgs.dockerTools.pullImage {
    imageName = "debian";
    imageDigest = "sha256:f8bbfa052db81e5b8ac12e4a1d8310a85d1509d4d0d5579148059c0e8b717d4e";
    sha256 = "RxqDaCm/uRWfwruipruYknaAbQPcuo7Sk3kO2SaFBGQ=";
    finalImageName = "debian";
    finalImageTag = "stable-slim";
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "futhark-oopsla24";
  tag = "latest";
  fromImage = image;
  contents = with pkgs;
    [futhark-original
     futhark-automap

     # Data files
     artifact

     # Dependencies
     coreutils
     bash
     findutils
     vim
     scc
     hyperfine
     gnuplot
     bc
    ];

  config = {
    Cmd = [ "/bin/bash"];
    WorkingDir = "${artifact}";
  };

}
