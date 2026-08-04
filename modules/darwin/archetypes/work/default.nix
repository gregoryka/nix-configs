{
  config,
  lib,

  ...
}:
let
  cfg = config.gregnix.archetypes.work;
in
{
  options.gregnix.archetypes.work = {
    enable = lib.mkEnableOption "the work archetype";
  };

  config = lib.mkIf cfg.enable {
    gregnix.tools.homebrew.enable = true;

    # `claude`'s cask has `auto_updates: true` (confirmed via `brew info
    # --cask claude`) -- normally that alone would
    # make `brew outdated`/`upgrade --cask` skip it, the same way `greedy:
    # false` does for other auto-updating casks elsewhere in this repo (see
    # gregnix.programs.graphical.apps._1password). But the app self-updates
    # in place outside Homebrew's own Cellar/metadata tracking, so `brew
    # bundle install` still fails trying to (re)install/upgrade it ("It
    # seems there is already an App at ..."). Skip it from `brew bundle`'s
    # install/upgrade cycle entirely; it's already installed and keeps
    # itself current.
    #
    # Must go through `homebrew.onActivation.extraEnv` (rendered straight
    # into the `brew bundle` invocation nix-darwin runs during activation),
    # not `environment.variables` -- that activation runs via `sudo
    # --preserve-env=PATH`, which drops every other env var, including ones
    # set by `environment.variables` in the login shell.
    # homebrew.onActivation.extraEnv.HOMEBREW_BUNDLE_CASK_SKIP = "claude";

    homebrew.casks = [
      "claude"
      "claude-code@latest"
    ];
  };
}
