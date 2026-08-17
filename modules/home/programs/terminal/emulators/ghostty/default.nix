{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.terminal.emulators.ghostty;

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  options.gregnix.programs.terminal.emulators.ghostty = with types; {
    enable = lib.mkEnableOption "the Ghostty terminal emulator";

    font = mkOpt str "Monaspace Neon NF" ''
      `font-family` for Ghostty. Defaults to the Nerd Font-patched variant
      shipped by `pkgs.monaspace` (see `gregnix.system.fonts`), so
      terminal icons (eza, starship, etc.) render without a separate
      symbol-fallback font.
    '';
  };

  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      package = if isDarwin then null else pkgs.ghostty;

      installBatSyntax = isLinux;
      installVimSyntax = isLinux;

      enableZshIntegration = true;

      # See: https://ghostty.org/docs/config/reference
      settings =
        lib.recursiveUpdate
          {
            font-family = cfg.font;
            font-size = 13;

            cursor-style = "block";
            cursor-style-blink = false;

            copy-on-select = "clipboard";
            clipboard-trim-trailing-spaces = true;

            mouse-hide-while-typing = true;
            focus-follows-mouse = false;

            window-padding-x = 4;
            window-padding-y = 4;
            window-save-state = "always";

            confirm-close-surface = false;
          }
          (
            if isDarwin then
              {
                macos-option-as-alt = true;
                macos-titlebar-style = "tabs";
                quit-after-last-window-closed = true;
              }
            else if isLinux then
              {
                window-decoration = false;
              }
            else
              { }
          );
    };
  };
}
