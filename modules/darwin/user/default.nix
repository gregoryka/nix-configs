{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.user;
in
{
  options.gregnix.user = {
    name = mkOpt types.str "gregory.kanter" "The user account.";
    email = mkOpt types.str "gregory.kanter@example.com" "The email of the user.";
    fullName = mkOpt types.str "Gregory Kanter" "The full name of the user.";
    uid = mkOpt (types.nullOr types.int) 501 "The uid for the user account.";
  };

  config = {
    users.users.${cfg.name} = {
      uid = mkIf (cfg.uid != null) cfg.uid;
      shell = pkgs.zsh;
      home = "/Users/${cfg.name}";
    };
  };
}
