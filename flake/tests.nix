{
  config,
  self,
  lib,
  ...
}:
let
  tests = import ../lib/tests { inherit self; };
in
{
  flake.tests = tests // {
    systems = lib.genAttrs config.systems (_system: tests);
  };
}
