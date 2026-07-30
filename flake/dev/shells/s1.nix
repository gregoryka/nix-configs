{
  lib,
  pkgs,
  ...
}:
let
  # nixpkgs does not expose versioned `clang-22`/`clang++-22`/`llvm-ar-22`
  # binaries directly, so alias them ourselves for convenience.
  versionedLlvmTools = pkgs.runCommand "s1-versioned-llvm-tools" { } ''
    mkdir -p "$out/bin"
    ln -s "${pkgs.clang_22}/bin/clang" "$out/bin/clang-22"
    ln -s "${pkgs.clang_22}/bin/clang++" "$out/bin/clang++-22"
    ln -s "${pkgs.llvmPackages_22.llvm}/bin/llvm-ar" "$out/bin/llvm-ar-22"
  '';

  packages = with pkgs; [
    clang_22
    llvmPackages_22.llvm
    llvmPackages_22.clang-tools # clangd, clang-tidy, clang-format
    gcc15.cc.lib # libstdc++15
    versionedLlvmTools
    uncrustify
    sccache
    meson
    ninja
    gnumake
    rustc
    cargo
    rust-cbindgen
  ];

  # Matches the fixed path set in modules/home/archetypes/work/default.nix's
  # `sops.secrets.artifactory_token.path`.
  artifactoryTokenPath = "$HOME/.local/state/sops-nix/artifactory_token";
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

    if [[ -f "${artifactoryTokenPath}" ]]; then
      ART_TOKEN="$(cat "${artifactoryTokenPath}")"
      export ART_TOKEN
      echo "🔑 ART_TOKEN loaded"
    else
      echo "⚠️  No artifactory token at ${artifactoryTokenPath} (run 'home-manager switch' first)"
    fi
  '';
}
