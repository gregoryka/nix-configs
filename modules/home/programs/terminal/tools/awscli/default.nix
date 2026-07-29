{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.terminal.tools.awscli;

  configFile = "${config.xdg.configHome}/aws/config";

  # botocore hardcodes these two cache directories under $HOME -- they
  # aren't affected by AWS_CONFIG_FILE/XDG -- so they're cleaned up as-is.
  cliCacheDir = "${config.home.homeDirectory}/.aws/cli/cache";
  ssoCacheDir = "${config.home.homeDirectory}/.aws/sso/cache";

  # Darwin only: no systemd-tmpfiles equivalent, so launchd runs this
  # instead (see systemd.user.tmpfiles.rules below for Linux).
  cleanupScript = pkgs.writeShellApplication {
    name = "awscli-cache-cleanup";
    runtimeInputs = [ pkgs.findutils ];
    text = ''
      find "${cliCacheDir}" "${ssoCacheDir}" \
        -type f -mmin +720 ! -name session.db -delete 2>/dev/null || true
    '';
  };
in
{
  options.gregnix.programs.terminal.tools.awscli = {
    enable = mkEnableOption "the AWS CLI";

    settings = mkOpt (types.attrsOf (types.attrsOf types.str)) { } ''
      AWS CLI config, keyed by INI section name (e.g. `"default"` or
      `"profile personal"`), written to `${config.xdg.configHome}/aws/config`
      via a sops template. Use `config.sops.placeholder."<secret-name>"` as
      the value for any field that should be decrypted from sops at
      activation time instead of stored in plaintext.
    '';
  };

  config = mkIf cfg.enable {
    # Reuse upstream for the package itself; its own `settings`/`credentials`
    # options are of no use here though, since they render straight to a
    # nix store path (via `home.file`) at build time -- incompatible with
    # sops decrypting values in at activation time, and hardcoded to
    # `~/.aws/{config,credentials}` regardless of XDG. Hence a separate sops
    # template + AWS_CONFIG_FILE override below.
    programs.awscli = {
      enable = true;
      package = pkgs.awscli2;
    };

    home.packages = mkIf pkgs.stdenv.hostPlatform.isDarwin [ cleanupScript ];

    # aws-cli only reads $HOME/.aws/config by default; point it at the XDG
    # location the sops template below actually writes to.
    home.sessionVariables.AWS_CONFIG_FILE = configFile;

    sops.templates."awscli-config" = mkIf (cfg.settings != { }) {
      path = configFile;
      content = lib.generators.toINI { } cfg.settings;
    };

    # `e`/`x` tmpfiles rules are a more direct match for "delete files older
    # than N, except for this one" than a hand-rolled oneshot unit + timer.
    systemd.user.tmpfiles.rules = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      "e ${cliCacheDir} 0700 - - 12h -"
      "x ${cliCacheDir}/session.db"
      "e ${ssoCacheDir} 0700 - - 12h -"
    ];

    launchd.agents.awscli-cache-cleanup = mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe cleanupScript) ];
        StartInterval = 3600;
        RunAtLoad = false;
      };
    };
  };
}
