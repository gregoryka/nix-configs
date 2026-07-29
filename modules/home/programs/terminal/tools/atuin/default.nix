{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.gregnix.programs.terminal.tools.atuin;
in
{
  options.gregnix.programs.terminal.tools.atuin = {
    enable = lib.mkEnableOption "atuin";
  };

  config = mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;

      daemon.enable = true;
    };
  };
}
