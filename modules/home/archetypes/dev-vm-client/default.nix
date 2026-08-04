{
  config,
  lib,

  ...
}:
let
  inherit (lib) mapAttrsToList concatStringsSep;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.archetypes.devVmClient;

  # Secretive (macOS Secure Enclave) agent socket, forwarded over to each dev
  # vm (via RemoteForward below) so it can use the same key for git signing
  # -- wired up in the `work` archetype's
  # `programs.git.settings.gpg.ssh.program`. This is the app's fixed sandbox
  # container path under the user's home directory (keyed by bundle ID).
  secretiveSocket = "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  secretiveForwardedSocket = "/run/user/1000/secretive.ssh";

  # Used only for the "-claude" Host aliases below: Claude Desktop's embedded
  # ssh2 client eagerly parses `IdentityFile` as private key material and
  # crashes on a public key file, so those aliases must be agent-only.
  onePasswordSocket = config.gregnix.programs.terminal.tools._1password-cli.sshSocket;
in
{
  options.gregnix.archetypes.devVmClient = {
    enable = lib.mkEnableOption "this Mac's ssh/signing setup for connecting to dev VMs";

    identityFile = mkOpt lib.types.str "" ''
      Path to this specific machine's Secretive-exported public key
      (Secure Enclave-backed, non-transferable to any other machine) used
      to authenticate to dev VMs.
    '';

    vms =
      mkOpt
        (lib.types.attrsOf (
          lib.types.submodule {
            options = {
              host = mkOpt lib.types.str "" ''
                Hostname or IP to connect to, usually a `config.sops.placeholder.*` value.
              '';
              hostKey = mkOpt lib.types.str "" ''
                SSH host public key (e.g. from `ssh-keyscan`); public, not secret.
              '';
            };
          }
        ))
        { }
        ''
          Dev VMs to set up an ssh `Host` block and known_hosts entry for, keyed
          by the ssh alias (e.g. `dev-vm`, `dev-vm-arm`).
        '';
  };

  config = lib.mkIf cfg.enable {
    gregnix.programs.terminal.tools.ssh = {
      extraKnownHosts = mapAttrsToList (_name: vm: "${vm.host} ${vm.hostKey}") cfg.vms;

      extraConfig = concatStringsSep "\n" (
        mapAttrsToList (name: vm: ''
          Host ${name}
            HostName ${vm.host}
            User user
            IdentityAgent ${secretiveSocket}
            IdentityFile ${cfg.identityFile}
            RemoteForward ${secretiveForwardedSocket} ${secretiveSocket}


          Host ${name}-claude
            HostName ${vm.host}
            User user
            IdentityAgent "${onePasswordSocket}"
            RemoteForward ${secretiveForwardedSocket} "${onePasswordSocket}"
        '') cfg.vms
      );
    };
  };
}
