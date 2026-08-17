{
  config,
  lib,

  ...
}:
let
  inherit (lib)
    types
    mkEnableOption
    mkIf
    mkMerge
    concatStringsSep
    mapAttrs'
    nameValuePair
    ;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.terminal.tools.ssh;

  githubKnownHosts = [
    "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
    "github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg="
    "github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk="
  ];
in
{
  options.gregnix.programs.terminal.tools.ssh = {
    enable = mkEnableOption "SSH";

    authorizedKeys = mkOpt (types.listOf types.str) [ ] "Public keys allowed to SSH into this machine.";

    extraConfig = mkOpt types.lines "" ''
      Extra ssh_config text, rendered via sops and pulled in with `Include`
      so values containing a `sops.placeholder` (e.g. a sensitive
      `HostName`) don't land in the plaintext Nix store.
    '';

    extraKnownHosts = mkOpt (types.listOf types.str) [ ] ''
      Extra `known_hosts` lines, in addition to the built-in ones, rendered
      via sops so entries containing a `sops.placeholder` (e.g. a sensitive
      hostname) don't land in the plaintext Nix store.
    '';

    identityFiles = mkOpt (types.attrsOf types.str) { } ''
      Public key contents (not secret) to materialize at
      `$XDG_CONFIG_HOME/ssh/<name>`, keyed by filename, so an
      `IdentityFile` directive elsewhere can point at a stable path
      instead of e.g. an app sandbox container path directly.
    '';
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Rendered unconditionally (content may be empty) so their presence in
      # `sops.templates` never depends on `cfg.extraConfig`/`extraKnownHosts`,
      # which themselves may read `sops.placeholder.*` -- placeholders only
      # become available once `sops.templates != {}`, so gating these template
      # *keys* on the same values would be a dependency cycle.
      sops.templates = {
        "ssh-extra-config".content = cfg.extraConfig;
        "ssh-extra-known-hosts".content = concatStringsSep "\n" cfg.extraKnownHosts;
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [ config.sops.templates."ssh-extra-config".path ];

        settings."*" = {
          AddKeysToAgent = "yes";
          ForwardAgent = false;
          # Our known_hosts entries are hostname-keyed; without this, an ssh
          # older/newer than nixpkgs' default could also try (and fail) to
          # verify the resolved IP separately.
          CheckHostIP = false;
          ServerAliveInterval = 30;
          ServerAliveCountMax = 2;
          StreamLocalBindUnlink = "yes";
          ConnectTimeout = 5;
          ControlMaster = "auto";
          ControlPath = "~/.ssh/controlmasters/%C";
          ControlPersist = "10m";
          # "~/.ssh/known_hosts" stays a regular, user-writable file so
          # normal TOFU prompts still work; the nix-managed entries live in
          # separate files since `home.file` is a read-only store symlink.
          UserKnownHostsFile = [
            "~/.ssh/known_hosts"
            "~/.ssh/nix-known-hosts"
            config.sops.templates."ssh-extra-known-hosts".path
          ];
        };
      };

      home.file = {
        ".ssh/nix-known-hosts".text = concatStringsSep "\n" githubKnownHosts;
        ".ssh/controlmasters/.keep".text = "";
      };
    }

    (mkIf (cfg.identityFiles != { }) {
      xdg.configFile = mapAttrs' (
        name: content: nameValuePair "ssh/${name}" { text = content; }
      ) cfg.identityFiles;
    })

    (mkIf (cfg.authorizedKeys != [ ]) {
      # Deliberately NOT `home.file`: that symlinks into the Nix store, and
      # sshd's StrictModes then refuses the key ("bad ownership or modes for
      # directory /nix/store", since the store is group-writable) -- silently
      # falling back to password auth. Materialize a real, plain file instead.
      home.activation.installAuthorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run install -d -m700 "$HOME/.ssh"
        cat > "$HOME/.ssh/authorized_keys" <<'EOF'
        ${concatStringsSep "\n" cfg.authorizedKeys}
        EOF
        run chmod 600 "$HOME/.ssh/authorized_keys"
      '';
    })
  ]);
}
