{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self.lib.file)
    filterDarwinSystems
    parseHomeConfigurations
    parseSystemConfigurations
    ;

  systemsPath = ../systems;
  homesPath = ../homes;
  allSystems = parseSystemConfigurations systemsPath;
  allHomes = parseHomeConfigurations homesPath;
  allDarwinModules = self.lib.file.importModulesRecursive ../modules/darwin;
  matchingHomes =
    system: hostname:
    lib.filterAttrs (
      _name: homeConfig: homeConfig.system == system && homeConfig.hostname == hostname
    ) allHomes;
in
{
  flake = {
    darwinConfigurations = lib.mapAttrs' (
      _name:
      { system, hostname, ... }:
      {
        name = hostname;
        value = self.lib.system.mkDarwin {
          inherit inputs system hostname;
          username = "gregory.kanter";
          darwinModules = allDarwinModules;
          matchingHomes = matchingHomes system hostname;
        };
      }
    ) (filterDarwinSystems allSystems);

    # NOTE: Home Manager configurations are handled by flake/home.nix
  };
}
