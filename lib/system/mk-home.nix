{ inputs }:
/**
  Create a Home Manager configuration.

  # Inputs

  `system`

  : System architecture

  `hostname`

  : Host name

  `username`

  : User name

  `modules`

  : List of additional modules
*/
{
  system,
  hostname,
  username ? "gregory.kanter",
  extraInputPatches ? { },
  modules ? [ ],
  ...
}:
let
  bootstrapCommon = import ./common.nix { inherit inputs; };
  patchedInputs = bootstrapCommon.mkPatchedInputs {
    inherit system extraInputPatches;
    patchableInputs = [
      "nixpkgs"
      "home-manager"
    ];
  };
  common = import ./common.nix { inputs = patchedInputs; };
  flake = patchedInputs.self or (throw "mkHome requires 'inputs.self' to be passed");

  extendedLib = common.mkExtendedLib flake patchedInputs.nixpkgs;
in
patchedInputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import patchedInputs.nixpkgs {
    inherit system;
    inherit ((common.mkNixpkgsConfig flake)) config overlays;
  };

  extraSpecialArgs = {
    inherit
      hostname
      username
      system
      ;
    osConfig = { };
    inputs = patchedInputs;
    inherit (patchedInputs) self;
    lib = extendedLib;
    flake-parts-lib = patchedInputs.flake-parts.lib;
  };

  modules = [ patchedInputs.sops-nix.homeManagerModules.sops ] ++ common.hmSharedModules ++ modules;
}
