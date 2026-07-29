{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) getExe mkForce mkIf;

  cfg = config.gregnix.programs.terminal.tools.ripgrep;
in
{
  options.gregnix.programs.terminal.tools.ripgrep = {
    enable = lib.mkEnableOption "ripgrep";
  };

  config = mkIf cfg.enable {
    programs.ripgrep = {
      enable = true;
      package = pkgs.ripgrep;

      arguments = [
        # ignore git files
        "--glob=!.git/*"

        "--smart-case"
      ];
    };

    home.shellAliases = {
      grep = mkForce (getExe config.programs.ripgrep.package);
    };
  };
}
