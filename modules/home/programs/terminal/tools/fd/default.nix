{
  config,
  lib,

  ...
}:
let
  cfg = config.gregnix.programs.terminal.tools.fd;
in
{
  options.gregnix.programs.terminal.tools.fd = {
    enable = lib.mkEnableOption "fd";
  };

  config = lib.mkIf cfg.enable {
    programs.fd.enable = true;
  };
}
