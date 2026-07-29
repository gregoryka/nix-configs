{
  config,
  lib,

  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.gregnix.programs.terminal.tools.gh;
in
{
  options.gregnix.programs.terminal.tools.gh = {
    enable = mkEnableOption "the gh CLI tool";

    gitCredentialHelper = {
      hosts = mkOption {
        type = types.listOf types.str;
        default = [
          "https://github.com"
          "https://gist.github.com"
        ];
        description = "A list of hosts for which gh should be used as a credential helper.";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.gh = {
      enable = true;

      gitCredentialHelper = {
        enable = true;
        inherit (cfg.gitCredentialHelper) hosts;
      };

      settings = {
        version = "1";
      };
    };
  };
}
