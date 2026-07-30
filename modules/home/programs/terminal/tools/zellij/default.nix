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
        default_mode = "locked";
        pane_frames = true;
      }
      # On Linux, leave copy_command unset so zellij falls back to OSC52
      # clipboard escape sequences -- these are forwarded through SSH to
      # the local terminal, unlike `wl-copy`, which requires a running
      # Wayland session and silently does nothing over SSH.
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        copy_command = "pbcopy";
      };
    };
  };
}
