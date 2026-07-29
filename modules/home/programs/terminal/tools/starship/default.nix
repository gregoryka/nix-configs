{
  config,
  lib,

  ...
}:
let
  cfg = config.gregnix.programs.terminal.tools.starship;
in
{
  options.gregnix.programs.terminal.tools.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
