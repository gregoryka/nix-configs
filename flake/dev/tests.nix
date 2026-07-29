{ inputs, lib, ... }:
let
  hasNixUnit = inputs.nix-unit ? modules;
in
{
  imports = lib.optional hasNixUnit inputs.nix-unit.modules.flake.default;

  perSystem = {
    nix-unit = lib.mkIf hasNixUnit {
      # `checks.<system>.nix-unit` evaluates root `self#tests` in the build
      # sandbox. Pass locked root inputs explicitly so the check stays offline.
      inputs = {
        inherit (inputs)
          flake-parts
          home-manager
          nix-darwin
          nixpkgs
          nur
          sops-nix
          ;
      };
    };
  };
}
