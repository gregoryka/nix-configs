{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.gregnix.system.fonts;
in
{
  options.gregnix.system.fonts = {
    enable = lib.mkEnableOption "managing fonts";
  };

  config = lib.mkIf cfg.enable {
    # Full Nerd Font-patched typeface (not just a symbols-only fallback) so
    # terminal icons (eza, starship) render reliably — macOS doesn't
    # automatically fall back to a separate font for Private Use Area
    # codepoints, so the icons need to be baked into the font actually
    # selected in the terminal. Set your terminal's font to
    # "Monaspace Neon NF".
    fonts.packages = [ pkgs.monaspace ];
  };
}
