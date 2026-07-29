{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.gregnix.programs.terminal.tools.zellij;
in
{
  options.gregnix.programs.terminal.tools.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      package = pkgs.zellij;

      settings = {
        copy_command = if pkgs.stdenv.hostPlatform.isDarwin then "pbcopy" else "wl-copy";
        default_mode = "locked";
        pane_frames = true;
      };
    };
  };
}
