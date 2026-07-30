{
  lib,
  pkgs,
  ...
}:
let
  packages = with pkgs; [
    clang_22
    llvmPackages_22.clang-tools # clangd, clang-tidy, clang-format
    gcc15.cc.lib # libstdc++15
    uncrustify
    sccache
    meson
    ninja
    gnumake
    rustc
    cargo
    rust-cbindgen
  ];
in
pkgs.mkShellNoCC {
  inherit packages;

  shellHook = ''
    echo "⚙️  S1 DevShell"
    echo ""
    echo "📦 Available packages:"
    ${lib.concatMapStringsSep "\n" (
      pkg: ''echo "  - ${pkg.pname or pkg.name or "unknown"} (${pkg.version or "unknown"})"''
    ) packages}
    echo ""
    echo "💡 C/C++ (clang 22 + libstdc++15) and Rust toolchain for S1"
  '';
}
