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

    homebrew.casks = [
      # `claude` auto-updates itself outside Homebrew (it self-manages
      # /Applications/Claude.app in place, as root). Forcing greedy upgrades
      # on it makes `brew bundle` fight the self-updater's on-disk state
      # every activation ("It seems there is already an App at ..."), which
      # even `--force`/`--adopt` don't resolve. Just track presence.
      {
        name = "claude";
        greedy = false;
      }
      "claude-code@latest"
    ];
  };
}
