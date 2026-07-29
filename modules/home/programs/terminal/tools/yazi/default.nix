{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.gregnix.programs.terminal.tools.yazi;
in
{
  options.gregnix.programs.terminal.tools.yazi = {
    enable = lib.mkEnableOption "yazi";
  };

  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;

      package = pkgs.yazi.override {
        _7zz = pkgs._7zip-zstd-rar; # Support for RAR extraction plus extra compression codecs
        extraPackages = with pkgs; [
          exiftool
          mediainfo
          undmg
        ];
      };

      enableBashIntegration = true;
      enableZshIntegration = true;
      shellWrapperName = "y";

      # Yazi configuration
      # See: https://yazi-rs.github.io/docs/configuration/overview/
      settings = lib.mkMerge [
        (import ./settings/open.nix)
        (import ./settings/opener.nix { inherit config lib; })
      ];
    };
  };
}
