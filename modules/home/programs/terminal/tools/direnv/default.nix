{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.gregnix) enabled;

  cfg = config.gregnix.programs.terminal.tools.direnv;
in
{
  options.gregnix.programs.terminal.tools.direnv = {
    enable = lib.mkEnableOption "direnv";
  };

  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = enabled;
      silent = true;
    };
  };
}
