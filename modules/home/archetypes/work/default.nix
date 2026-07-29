{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.gregnix.archetypes.work;
in
{
  options.gregnix.archetypes.work = {
    enable = lib.mkEnableOption "the work archetype";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.awscli2 ];
  };
}
