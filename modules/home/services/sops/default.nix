{
  config,
  lib,
  pkgs,
  inputs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.services.sops;
in
{
  options.gregnix.services.sops = {
    enable = lib.mkEnableOption "sops";
    defaultSopsFile = mkOpt (lib.types.nullOr lib.types.path) null "Default sops file.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.rage
      pkgs.sops
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      pkgs.gregnix.age-plugin-tagpq
      # Decryption identity is Secure Enclave-backed (age-plugin-se, hybrid
      # P256 + ML-KEM-768 for post-quantum security). Generate one with:
      #   age-plugin-se keygen --pq -o ~/.config/sops/age/keys.txt
      inputs.nur.legacyPackages.${pkgs.stdenv.hostPlatform.system}.repos.josh.age-plugin-se
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      pkgs.gregnix.age-plugin-pq
    ];

    sops = {
      inherit (cfg) defaultSopsFile;
      defaultSopsFormat = "yaml";

      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
  };
}
