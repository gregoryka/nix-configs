{ inputs }:
/**
  Create a Darwin system configuration.

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
  matchingHomes ? null,
  darwinModules ? null,
  sharedHomeModules ? null,
  extraInputPatches ? { },
  modules ? [ ],
  ...
}:
let
  bootstrapCommon = import ./common.nix { inherit inputs; };
  patchedInputs = bootstrapCommon.mkPatchedInputs {
    inherit system extraInputPatches;
  };
  common = import ./common.nix { inputs = patchedInputs; };
  flake = patchedInputs.self or (throw "mkDarwin requires 'inputs.self' to be passed");

  extendedLib = common.mkExtendedLib flake patchedInputs.nixpkgs;
  baseDarwinModules =
    if darwinModules == null then
      (extendedLib.importModulesRecursive ../../modules/darwin)
    else
      darwinModules;
  resolvedMatchingHomes =
    if matchingHomes == null then
      common.mkHomeConfigs {
        inherit
          flake
          system
          hostname
          ;
      }
    else
      matchingHomes;
  homeManagerConfig = common.mkHomeManagerConfig {
    inherit
      extendedLib
      system
      hostname
      sharedHomeModules
      ;
    inputs = patchedInputs;
    matchingHomes = resolvedMatchingHomes;
    isNixOS = false;
  };
in
patchedInputs.nix-darwin.lib.darwinSystem {
  inherit system;

  specialArgs = common.mkSpecialArgs {
    inherit
      hostname
      username
      extendedLib
      ;
    inputs = patchedInputs;
  };

  modules = [
    # Configure nixpkgs with overlays
    {
      nixpkgs = {
        inherit system;
      }
      // common.mkNixpkgsConfig flake;
    }

    patchedInputs.home-manager.darwinModules.home-manager
    patchedInputs.sops-nix.darwinModules.sops

    # Auto-inject home configurations for this system+hostname
    homeManagerConfig

    # Import all darwin modules recursively
  ]
  ++ baseDarwinModules
  ++ [
    ../../systems/${system}/${hostname}
  ]
  ++ modules;
}
