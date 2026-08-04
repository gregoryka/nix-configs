{
  config,
  lib,

  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.gregnix.programs.terminal.tools._1password-cli;
in
{
  options.gregnix.programs.terminal.tools._1password-cli = {
    enable = mkEnableOption ''
      the 1Password CLI. The actual package (GUI + CLI) is installed via
      Homebrew casks on the darwin side -- see
      gregnix.programs.graphical.apps._1password -- this module only
      exposes shared config (e.g. the SSH agent socket path) for other
      modules to consume
    '';

    enableSshSocket = mkEnableOption "using the 1Password SSH agent for all hosts (sets IdentityAgent under Host *)";

    sshSocket = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.home.homeDirectory}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      description = ''
        1Password's SSH agent socket path (fixed, same on every Mac -- the
        "2BUA8C4S2C" segment is AgileBits' Apple Team ID, not
        machine-specific).
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.ssh.settings."*" = mkIf cfg.enableSshSocket {
      IdentityAgent = cfg.sshSocket;
    };
  };
}
