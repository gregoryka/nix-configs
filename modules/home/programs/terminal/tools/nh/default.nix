{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.gregnix.programs.terminal.tools.nh;

  switchTarget = if pkgs.stdenv.hostPlatform.isLinux then "os" else "darwin";
in
{
  options.gregnix.programs.terminal.tools.nh = {
    enable = lib.mkEnableOption "nh";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;

      clean.enable = true;

      flake = "${config.home.homeDirectory}/gitrepos/nix-configs";
    };

    home = {
      sessionVariables = {
        NH_SEARCH_PLATFORM = 1;
      };
      shellAliases = {
        nixre = "nh ${switchTarget} switch";
        nixre-fast = "nh ${switchTarget} switch --option max-jobs auto --option cores 0";
      };
    };
  };
}
