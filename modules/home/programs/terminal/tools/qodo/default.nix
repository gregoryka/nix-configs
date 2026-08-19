{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.gregnix) mkOpt mkSecretsWrapper;

  cfg = config.gregnix.programs.terminal.tools.qodo;

  # `pkgs.gregnix.qodo-cli-skills.skillNames` (a plain Nix list, not
  # discovered via `builtins.readDir`) is the single source of truth for
  # these names -- see that package's comment for why avoiding
  # import-from-derivation here matters. `genAttrs` below just builds
  # name -> directory mappings by string concatenation, which is pure and
  # doesn't force building either output.
  mkSkillEntries = dir: lib.genAttrs pkgs.gregnix.qodo-cli-skills.skillNames (name: "${dir}/${name}");

  needsWrapper = cfg.urlSopsFile != null || cfg.tokenRef != null || cfg.tokenSopsFile != null;

  qodoWrapped = mkSecretsWrapper {
    inherit pkgs;
    name = "qodo";
    executable = lib.getExe pkgs.gregnix.qodo-cli;

    opEnv = lib.optionalAttrs (cfg.tokenRef != null) {
      QODO_API_KEY = cfg.tokenRef;
    };

    sopsEnv =
      lib.optionalAttrs (cfg.urlSopsFile != null) (
        let
          url = {
            sopsFile = cfg.urlSopsFile;
            key = cfg.urlSopsKey;
          };
        in
        {
          # Both point at the same field: `resolveCredentials()` in
          # qodo.mjs needs `QODO_BASE_URL` (paired with a token, for fully
          # non-interactive use); `QODO_AUTH_URL` covers interactive
          # `qodo login`/`setup` against the same self-hosted platform.
          QODO_AUTH_URL = url;
          QODO_BASE_URL = url;
        }
      )
      // lib.optionalAttrs (cfg.tokenSopsFile != null) {
        QODO_API_KEY = {
          sopsFile = cfg.tokenSopsFile;
          key = cfg.tokenSopsKey;
        };
      };
  };
in
{
  options.gregnix.programs.terminal.tools.qodo = {
    enable = mkEnableOption "the Qodo CLI";

    urlSopsFile = mkOpt (types.nullOr types.path) null ''
      Path to a sops-encrypted file holding the self-hosted Qodo platform
      URL (see `urlSopsKey`). Decrypted at invocation time by the
      wrapper -- never rendered to disk -- and exported as both
      `QODO_AUTH_URL` (interactive `qodo login`/`setup`) and
      `QODO_BASE_URL` (paired with a token for fully non-interactive use,
      per `resolveCredentials()` in qodo.mjs). Leave `null` for Qodo's
      public cloud.
    '';

    urlSopsKey = mkOpt types.str "qodo_url" "Key within `urlSopsFile` holding the URL.";

    tokenRef = mkOpt (types.nullOr types.str) null ''
      1Password reference (e.g. `op://Vault/item/field`) for the Qodo API
      token. ARCHITECTURE.md's primary mechanism for CLI tool credentials:
      injected into the process environment via `op run` at invocation
      time, never written to disk or the Nix store.
    '';

    tokenSopsFile = mkOpt (types.nullOr types.path) null ''
      Path to a sops-encrypted file holding the Qodo API token (see
      `tokenSopsKey`), for hosts without 1Password available.
      ARCHITECTURE.md's fallback: runtime sops decryption with Nix
      managing the wrapper. Set at most one of `tokenRef`/`tokenSopsFile`
      per host.
    '';

    tokenSopsKey = mkOpt types.str "qodo_token" "Key within `tokenSopsFile` holding the token.";
  };

  config = mkIf cfg.enable {
    home.packages = [ (if needsWrapper then qodoWrapped else pkgs.gregnix.qodo-cli) ];

    # Contribute Qodo's bundled skills declaratively (rather than
    # `qodo skills install` at activation time) via each agent tool
    # module's own merge point -- they own their config directories, qodo
    # only feeds into them.
    gregnix.programs.terminal.tools.claude-code.skills =
      mkSkillEntries pkgs.gregnix.qodo-cli-skills.claudeCode;
    gregnix.programs.terminal.tools.devin.skills = mkSkillEntries pkgs.gregnix.qodo-cli-skills.devin;
  };
}
