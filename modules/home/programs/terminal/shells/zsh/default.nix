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

        # Unlike bash, zsh never sources /etc/profile or /etc/profile.d/*.sh
        # (that's a bash/sh login convention, not a zsh one). On non-NixOS
        # hosts, that's normally where a multi-user Nix install's own
        # PATH/NIX_PATH setup lives, so without this, no nix-installed
        # executable is found once zsh (rather than bash) is the login
        # shell -- source it explicitly, covering common installer layouts.
        for __nix_profile_script in /etc/profile.d/nix.sh /etc/profile.d/nix-daemon.sh "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
          if [[ -e "$__nix_profile_script" ]]; then
            emulate sh -c "source '$__nix_profile_script'"
          fi
        done
        unset __nix_profile_script
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
