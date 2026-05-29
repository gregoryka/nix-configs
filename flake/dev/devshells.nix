{
  inputs,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      self,
      self',
      system,
      config,
      ...
    }:
    let
      shellsPath = ./shells;
      shellFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) (
        builtins.readDir shellsPath
      );
      shellNames = lib.mapAttrsToList (name: _: lib.removeSuffix ".nix" name) shellFiles;

    in
    {
      devShells = lib.genAttrs shellNames (
        name:
        import (shellsPath + "/${name}.nix") {
          inherit
            config
            inputs
            lib
            pkgs
            self
            self'
            system
            ;
        }
      );
    };
}
