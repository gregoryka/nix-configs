{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.terminal.emulators.kitty;

  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  options.gregnix.programs.terminal.emulators.kitty = with types; {
    enable = lib.mkEnableOption "the kitty terminal emulator";

    font = mkOpt str "Monaspace Neon NF" ''
      `font_family` for kitty. Defaults to the Nerd Font-patched variant
      shipped by `pkgs.monaspace` (see `gregnix.system.fonts`), so
      terminal icons (eza, starship, etc.) render without a separate
      symbol-fallback font.
    '';
  };

  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      enableGitIntegration = true;

      package = if isDarwin then null else pkgs.kitty;

      darwinLaunchOptions = lib.optionals isDarwin [ "--single-instance" ];

      settings =
        lib.recursiveUpdate
          {
            # Font
            font_family = cfg.font;
            font_size = 13;
            disable_ligatures = "never";

            # Cursor
            cursor_shape = "beam";
            cursor_blink_interval = 0;

            # Scrollback
            scrollback_lines = 20000;
            scrollback_pager = "less";

            # Terminal bell
            enable_audio_bell = false;
            visual_bell_duration = 0;

            # Window layout
            window_padding_width = 4;
            hide_window_decorations = "yes";
            confirm_os_window_close = 0;
            remember_window_size = false;
            initial_window_width = 900;
            initial_window_height = 550;

            # Tabs
            tab_bar_style = "powerline";
            tab_bar_edge = "bottom";

            # Misc behavior
            update_check_interval = 0;
            allow_remote_control = "socket-only";
            term = "xterm-kitty";
          }
          (
            if isDarwin then
              {
                macos_option_as_alt = "left";
                macos_titlebar_color = "background";
                macos_quit_when_last_window_closed = true;
              }
            else if isLinux then
              {
                linux_display_server = "auto";
              }
            else
              { }
          );

      # "cmd" is only a valid kitty modifier on macOS; fall back to the
      # cross-platform "ctrl+shift" convention everywhere else.
      keybindings =
        let
          mod = if isDarwin then "cmd" else "ctrl+shift";
        in
        {
          "${mod}+c" = "copy_to_clipboard";
          "${mod}+v" = "paste_from_clipboard";
          "${mod}+enter" = "new_window";
          "${mod}+t" = "new_tab";
          "${mod}+w" = "close_tab";
          "${mod}+]" = "next_tab";
          "${mod}+[" = "previous_tab";
          "${mod}+equal" = "increase_font_size";
          "${mod}+minus" = "decrease_font_size";
          "${mod}+0" = "restore_font_size";
        };

      shellIntegration.enableZshIntegration = true;
    };
  };
}
