{
  lib,
  pkgs,
  ...
}:
let
  packages = with pkgs; [
    deadnix
    nh
    statix
    sops
  ];
in
pkgs.mkShellNoCC {
  inherit packages;

  shellHook = ''
    echo "🚀 GregNix development environment"
    echo ""
    echo "📦 Available packages:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) packages}
    echo ""
    echo "🔧 Common commands:"
    echo "  nix flake check       - Run all checks"
    echo "  statix check          - Check for anti-patterns"
    echo "  deadnix               - Find unused code"
    echo "  nh search <query>     - Search nixpkgs"
    echo "  sops                  - Manage secrets"
    echo ""
    echo "💡 Tip: Run 'nix flake show' to see all available dev shells"
  '';
}
