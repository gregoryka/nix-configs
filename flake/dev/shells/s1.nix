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
    popt
    meson
    ninja
    gnumake
    rustc
    cargo
    clippy
    rustfmt
    rust-cbindgen
    rust-bindgen
  ];

  # Matches the fixed path set in modules/home/archetypes/work/default.nix's
  # `sops.secrets.artifactory_token.path`.
  artifactoryTokenPath = "$HOME/.local/state/sops-nix/artifactory_token";

  # clang_22's default hardening flags, minus fortify/fortify3.
  hardeningFlags = lib.concatStringsSep " " (
    lib.subtractLists [ "fortify" "fortify3" ] pkgs.clang_22.defaultHardeningFlags
  );
in
pkgs.mkShellNoCC {
  inherit packages;

  shellHook = ''
    export NIX_HARDENING_ENABLE="${hardeningFlags}"

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
