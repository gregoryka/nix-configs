{
  config,
  lib,
  osConfig ? { },
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.gregnix.programs.terminal.shell.zsh;
  hasSystemZsh = osConfig.programs.zsh.enable or false;
in
{
  options.gregnix.programs.terminal.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      package = pkgs.zsh;

      autocd = true;
      enableCompletion = true;
      enableVteIntegration = true;

      dotDir = "${config.xdg.configHome}/zsh";

      # Disable /etc/{zshrc,zprofile} which contain the "sane-default" setup
      # out of the box, to avoid incorrect precedence over our own zshrc.
      envExtra = mkIf (!hasSystemZsh) ''
        setopt no_global_rcs
      '';

      history = mkIf (!config.gregnix.programs.terminal.tools.atuin.enable) {
        path = "${config.xdg.dataHome}/zsh/zsh_history";
        extended = true;
        save = 100000;
        size = 100000;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        saveNoDups = true;
        findNoDups = true;
      };

      syntaxHighlighting.enable = true;

      plugins = [
        {
          name = "zsh-vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
    };
  };
}
