{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf concatStringsSep;

  cfg = config.gregnix.programs.terminal.tools.terminfo;

  # Lightweight `terminfo`-only outputs (just the compiled database entry --
  # not the full GUI app) for the terminal emulators used as SSH *clients*
  # elsewhere in this flake (see `programs.terminal.emulators.{kitty,ghostty}`
  # on the Mac). Neither kitty nor Ghostty's `TERM` value (`xterm-kitty` /
  # `xterm-ghostty`) is in most distros' default terminfo database yet, and
  # when this machine is the remote end of an SSH session, zsh/readline's
  # capability queries silently fail and keystrokes get garbled/duplicated on
  # the client -- see https://github.com/kovidgoyal/kitty/issues/3996 and
  # https://ghostty.org/docs/help/terminfo#ssh. Installing the entries here
  # fixes it for every client, permanently, without any client-side
  # workaround (e.g. downgrading to `TERM=xterm-256color`, which loses
  # features).
  terminfoPackages = [
    pkgs.kitty.terminfo
    pkgs.ghostty.terminfo
  ];
in
{
  options.gregnix.programs.terminal.tools.terminfo = {
    enable = mkEnableOption ''
      terminfo database entries for kitty and Ghostty, so `$TERM` is
      recognized correctly when this machine is the remote end of an SSH
      session from one of those terminals
    '';
  };

  config = mkIf cfg.enable {
    home.packages = terminfoPackages;

    # A trailing empty component (from the unset-`$TERMINFO_DIRS` case) is
    # not a no-op: ncurses treats it as "also fall back to the compiled-in
    # default search list", so this only adds to that list rather than
    # replacing it.
    home.sessionVariables.TERMINFO_DIRS = concatStringsSep ":" (
      map (pkg: "${pkg}/share/terminfo") terminfoPackages ++ [ "$TERMINFO_DIRS" ]
    );
  };
}
