{
  config,
  lib,
  hostname,

  ...
}:
let
  inherit (lib) getFile;

  cfg = config.gregnix.archetypes.work;

  awsSecretsFile = getFile "secrets/work/aws.yaml";
  artifactorySecretsFile = getFile "secrets/work/${hostname}/artifactory.yaml";
in
{
  options.gregnix.archetypes.work = {
    enable = lib.mkEnableOption "the work archetype";
  };

  config = lib.mkIf cfg.enable {
    gregnix.programs.terminal.tools.awscli = {
      enable = true;
      settings = {
        default = {
          region = "us-east-1";
          output = "json";
          sso_session = "S1 dev";
          sso_account_id = config.sops.placeholder.sso_account_id;
          sso_role_name = config.sops.placeholder.sso_role_name;
        };
        "sso-session 'S1 dev'" = {
          sso_region = "us-east-1";
          sso_registration_scopes = "sso:account:access";
          sso_start_url = config.sops.placeholder.sso_start_url;
        };
      };
    };

    sops.secrets = {
      sso_account_id.sopsFile = awsSecretsFile;
      sso_start_url.sopsFile = awsSecretsFile;
      sso_role_name.sopsFile = awsSecretsFile;
      artifactory_token = {
        sopsFile = artifactorySecretsFile;
        # Pinned to a fixed, known path so devShells can read it directly.
        path = "${config.home.homeDirectory}/.local/state/sops-nix/artifactory_token";
      };
    };
  };
}
