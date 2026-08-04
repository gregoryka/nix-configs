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

    # `claude` has a real (non-`:latest`) pinned version in its cask recipe,
    # so `greedy: false` doesn't exempt it from `brew outdated` the way it
    # does for genuine `version :latest` casks -- it still shows up as
    # outdated whenever the recipe bumps, and `brew bundle install` upgrades
    # outdated deps by default. But the app self-updates in place outside
    # Homebrew's bookkeeping, so that upgrade attempt always fails
    # ("It seems there is already an App at ..."). Skip it from `brew
    # bundle`'s install/upgrade cycle entirely; it's already installed and
    # keeps itself current.
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
