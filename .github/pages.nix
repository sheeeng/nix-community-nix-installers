{
  pkgs ? (
    let
      flakeLock = builtins.fromJSON (builtins.readFile ../flake.lock);
    in
    import "${builtins.fetchTree flakeLock.nodes.nixpkgs.locked}" { }
  ),
  lib ? pkgs.lib,
}:

let
  inherit (lib) genAttrs attrNames;

  impls = {
    lix = {
      link = "https://lix.systems/about/#why-lix";
      description = "A fork of Nix";
    };
    nix = {
      link = "https://nixos.org/";
      description = "The official Nix implementation";
    };
  };

  formats = [
    "deb"
    "pacman"
    "rpm"
  ];

  systems = {
    "x86_64" = pkgs;
    "aarch64" = pkgs.pkgsCross.aarch64-multiplatform;
  };

  installers = genAttrs (lib.attrNames impls) (
    impl:
    genAttrs formats (
      format:
      genAttrs (attrNames systems) (
        system:
        let
          pkgs = systems.${system};
          installers' = import ../. { inherit pkgs lib; };
          pkg = installers'.${impl}.${format};
        in
        {
          store_path = "${pkg}";
          inherit (pkg) version;
        }
      )
    )
  );

in
pkgs.runCommand "github-pages" {
  inherit impls installers;
  __structuredAttrs = true;
  PATH = "${pkgs.coreutils}/bin:${pkgs.python3}/bin:${pkgs.pandoc}/bin";
  builder = builtins.toFile "builder" ''
    . .attrs.sh
    python3 ${./pages.py} ${../README.md} .attrs.json ''${outputs[out]}
  '';
} ""
