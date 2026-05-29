{
  inputs,
  lib,
  ...
}:
{
  imports = lib.optional (inputs.treefmt-nix ? flakeModule) inputs.treefmt-nix.flakeModule;

  perSystem =
    { pkgs, ... }:
    {
      treefmt = lib.mkIf (inputs.treefmt-nix ? flakeModule) {
        flakeCheck = true;
        flakeFormatter = true;

        projectRootFile = "flake.nix";

        programs = {
          deadnix = {
            enable = true;
            no-lambda-arg = true;
          };
          nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
          statix = {
            enable = true;
            priority = -2;
          };
        };

        settings = {
          global.excludes = [
            "*.lock"
            "flake.lock"
            ".git/*"
          ];
        };
      };
    };
}
