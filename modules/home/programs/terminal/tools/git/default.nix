{
  config,
  lib,

  ...
}:
let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.gregnix) mkOpt;
  inherit (config.gregnix) user;

  cfg = config.gregnix.programs.terminal.tools.git;
in
{
  options.gregnix.programs.terminal.tools.git = {
    enable = mkEnableOption "Git";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    signingKey =
      mkOpt types.str "${config.home.homeDirectory}/.ssh/id_ed25519"
        "The key ID to sign commits with.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
  };

  config = mkIf cfg.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;

      options = {
        dark = true;
        line-numbers = true;
        navigate = true;
        side-by-side = true;
      };
    };

    # Not wired up as the default git diff viewer (delta is); invoke on
    # demand via the `difft` alias below.
    programs.difftastic.enable = true;

    programs.git = {
      enable = true;

      settings = {
        alias.difft = "-c diff.external=difft diff";

        init.defaultBranch = "main";

        pull.rebase = true;

        push = {
          autoSetupRemote = true;
          default = "current";
        };

        rerere.enabled = true;

        user = {
          name = cfg.userName;
          email = cfg.userEmail;
        };
      };

      signing = {
        key = cfg.signingKey;
        format = "ssh";
        inherit (cfg) signByDefault;
      };
    };
  };
}
