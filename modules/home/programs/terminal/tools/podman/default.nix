{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.gregnix.programs.terminal.tools.podman;
in
{
  options.gregnix.programs.terminal.tools.podman = {
    enable = mkEnableOption "Podman (daemonless container engine)";
  };

  config = mkIf cfg.enable {
    # On Darwin this also declaratively creates/manages the
    # "podman-machine-default" VM (services.podman.useDefaultMachine
    # defaults to true there) and keeps it running via a launchd watchdog
    # agent. See home-manager's modules/services/podman/darwin.nix.
    services.podman.enable = true;
  };
}
