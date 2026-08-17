{
  config,
  lib,

  ...
}:
let
  inherit (lib) types mkEnableOption mkIf;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.terminal.tools.npm;

  authTokenLine = "_authToken=\${${cfg.authTokenEnvVar}}";
in
{
  options.gregnix.programs.terminal.tools.npm = {
    enable = mkEnableOption "npm's global ~/.npmrc";

    hostPath = mkOpt types.str "" ''
      Registry host + path, *without* a scheme (e.g.
      `artifactory.example.com/artifactory/api/npm/npm-remote/`).
      Deliberately schemeless: this is typically fed a
      `config.sops.placeholder.*` value, which is an opaque marker at eval
      time -- Nix-level string functions (e.g. stripping a scheme) can't
      operate on the real secret, only literal concatenation is safe.
      `scheme` below supplies the prefix instead.
    '';

    scheme = mkOpt types.str "https" "Scheme prepended to `hostPath` for the `registry` line.";

    authTokenEnvVar = mkOpt types.str "ARTIFACTORY_NPM_TOKEN" ''
      Name of the environment variable npm will substitute at request time
      for `_authToken` (via its own `''${...}` config syntax). Populate it
      out-of-band (e.g. `op run`) -- the token itself never lands here.
    '';
  };

  config = mkIf cfg.enable {
    sops.templates."npmrc" = {
      path = "${config.home.homeDirectory}/.npmrc";
      content = ''
        registry=${cfg.scheme}://${cfg.hostPath}
        //${cfg.hostPath}:${authTokenLine}
        always-auth=true
        min-release-age=7
      '';
    };
  };
}
