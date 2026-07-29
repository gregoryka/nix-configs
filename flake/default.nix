{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  imports = [
    ../lib
    ./configs.nix
    ./home.nix
    ./packages.nix
    ./tests.nix
    inputs.flake-parts.flakeModules.partitions
  ];

  partitions.dev = {
    module = ./dev;
    extraInputsFlake = ./dev;
  };

  partitionedAttrs = lib.genAttrs [
    "checks"
    "devShells"
    "formatter"
  ] (_: "dev");
}
