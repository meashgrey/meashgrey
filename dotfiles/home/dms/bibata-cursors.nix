{ pkgs }:

let
  archive = pkgs.fetchurl {
    url = "https://github.com/SakibShahariar/material-bibata-cursor/releases/download/v1.5.0/bibata-material-dark-v1.5.0.tar.gz";
    hash = "sha256-igz93WB4fGWgeM5JS1cIwdaPPldhGP3gcBlJ7bQMugQ=";
  };
in
pkgs.runCommand "material-bibata-cursors-1.5.0" {} ''
  mkdir -p "$out/share/icons"
  tar -xzf ${archive} --strip-components=1 -C "$out/share/icons"
''
