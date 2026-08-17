{
  config,
  lib,
  pkgs,
  inputs,
  osConfig ? { },

  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optionalAttrs
    types
    ;
  inherit (lib.gregnix) mkOpt;

  cfg = config.gregnix.programs.graphical.apps.vicinae;

  jsonFormat = pkgs.formats.json { };

  # `nix-settings.json` itself carries the (only conditionally-present)
  # `imports` link to the sops-rendered secretSettings file. Vicinae's
  # `Manager::load` recursively resolves `imports` for every file it loads,
  # not just the top-level one, so this nested import works exactly like a
  # top-level one would. This lets `settings.json`'s own `imports` entry
  # stay a single, permanently-static `"nix-settings.json"` string
  # regardless of whether `secretSettings` is used, which in turn lets its
  # activation stub below go back to a simple one-shot write instead of
  # having to reconcile a dynamic array on every activation.
  nixSettingsFile = jsonFormat.generate "vicinae-nix-settings" (
    cfg.settings
    // optionalAttrs (cfg.secretSettings != { }) {
      imports = [ config.sops.templates."vicinae-secret-settings".path ];
    }
  );

  vicinaeLib = inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system};
in
{
  options.gregnix.programs.graphical.apps.vicinae = {
    enable = mkOption {
      type = types.bool;
      default = osConfig.gregnix.programs.graphical.apps.vicinae.enable or false;
      description = "Whether to manage Vicinae's settings/extensions declaratively.";
    };

    settings = mkOpt jsonFormat.type { } ''
      Vicinae settings. Written as a plain Nix store JSON file to
      `~/.config/vicinae/nix-settings.json`, pulled in via an `imports` key
      from `~/.config/vicinae/settings.json` (which stays a real, writable
      file since Vicinae writes back to it when settings are changed from
      the GUI -- a Nix store symlink there would break that).

      Values here must NOT contain `config.sops.placeholder.<name>` tokens
      -- this file is a plain Nix store artifact with no secret
      substitution, so a placeholder would land here completely unresolved.
      Use `secretSettings` instead for anything that needs one.

      TODO(linux): `encrypt_sensitive_data` defaults to `false` upstream on
      Linux (`true` on macOS/Windows), so extension `password`-type
      preferences land in plaintext in `~/.local/share/vicinae/vicinae.db`'s
      `storage_data_item` table instead of being SQLCipher-encrypted behind
      a freedesktop Secret Service (gnome-keyring/KWallet) key. When a Linux
      gregnix host gains this module, either set
      `settings.encrypt_sensitive_data = true` here (requires a working
      Secret Service provider at login) or explicitly document/accept the
      plaintext-token trade-off.
    '';

    secretSettings = mkOpt jsonFormat.type { } ''
      Same shape as `settings` (deep-merged on top of it by Vicinae itself,
      via a second `imports` entry -- see `Manager::load`'s `glz::merge`,
      which recursively merges nested objects rather than replacing them
      wholesale, so e.g. `settings.providers.X.preferences.foo` and
      `secretSettings.providers.X.preferences.bar` compose fine), but for
      values that must be `config.sops.placeholder.<name>` tokens.

      Rendered through a `sops.templates` entry instead of a plain Nix
      store file, so placeholders get substituted with the real decrypted
      secret at activation time, without the secret ever landing in the
      (world-readable) Nix store. Kept separate from `settings` so a
      sops-nix decryption failure (missing key, locked Secure Enclave,
      etc.) only breaks the handful of settings that actually need a
      secret, not the whole file.
    '';

    extensions = mkOpt (types.listOf types.package) [ ] ''
      Vicinae/Raycast extension packages to symlink into
      `~/.local/share/vicinae/extensions`. Build entries with
      `mkRaycastExt` below (for github:raycast/extensions) or
      `inputs.vicinae.lib.<system>.mkVicinaeExtension`.
    '';

    raycastExtensionsRev = mkOpt types.str "a6faca32d6e243f35c3b3eeb881139aaad105d90" ''
      Pinned github:raycast/extensions commit `mkRaycastExt` below
      sparse-checks out from. Centralized here (rather than a flake input,
      which would have to fetch the whole monorepo non-sparsely) so every
      extension shares one rev without duplicating it -- bump this single
      value, then refresh each extension's content hash.
    '';

    raycastCliHashes =
      mkOpt (types.attrsOf types.str)
        {
          "1.39.2" = "03dkyzd8ln8s1q59kvripzy85fy16jsrq6xiv80a93rn5ly8zhdg";
        }
        ''
          Maps a `@raycast/api` version to the sha256 of its `ray` CLI binary
          from `cli.raycast.com/<version>/<arch>/ray`. Only older
          `@raycast/api` releases (`bin.ray = "bin/ray"` in their
          package.json) need this -- that wrapper downloads a native binary
          at build time otherwise, breaking pure/offline builds. Newer
          releases ship a self-contained, pure-JS oclif CLI at `bin/run.js`
          instead and need no network access at all, so extensions pinned to
          a version not listed here are assumed to be the newer kind and left
          untouched. Compute a missing entry via
          `nix-prefetch-url --type sha256 https://cli.raycast.com/<version>/<arch>/ray`.
        '';

    mkRaycastExt = mkOption {
      type = lib.types.functionTo (lib.types.functionTo types.package);
      readOnly = true;
      default =
        name: hash:
        let
          ext = vicinaeLib.mkRayCastExtension {
            inherit name hash;
            rev = cfg.raycastExtensionsRev;
          };
          apiVersion =
            (builtins.fromJSON (builtins.readFile (ext.src + "/package-lock.json")))
            .packages."node_modules/@raycast/api".version;
          cliHash = cfg.raycastCliHashes.${apiVersion} or null;
          arch =
            if pkgs.stdenv.hostPlatform.isLinux then
              "linux"
            else if pkgs.stdenv.hostPlatform.isAarch64 then
              "arm64"
            else
              "x86";
        in
        (
          if cliHash == null then
            ext
          else
            ext.overrideAttrs (old: {
              preBuild = ''
                install -Dm755 ${
                  pkgs.fetchurl {
                    url = "https://cli.raycast.com/${apiVersion}/${arch}/ray";
                    sha256 = cliHash;
                  }
                } "node_modules/@raycast/api/bin/${arch}/ray"
              ''
              + (old.preBuild or "");
            })
        ).overrideAttrs
          (old: {
            # Some extensions (e.g. `brew`) ship a helper script under
            # `assets/` (checked into upstream git as non-executable) that
            # they lazily `chmod +x` themselves on first run. That self-heal
            # fails here since the extension is symlinked read-only from the
            # Nix store into `~/.local/share/vicinae/extensions`, so make any
            # such scripts executable at build time instead.
            postInstall = ''
              if [ -d "$out/assets" ]; then
                find "$out/assets" -name '*.sh' -exec chmod +x {} +
              fi
            ''
            + (old.postInstall or "");
          });
      description = ''
        Builds a `github:raycast/extensions` extension package, given the
        extension directory's `name` and its sparse-checkout content
        `hash` (each extension does its own `fetchFromGitHub` sparse
        checkout at `raycastExtensionsRev`, so hashes differ per
        extension). Also injects the `ray` CLI binary per
        `raycastCliHashes` when the extension's `@raycast/api` version
        needs it.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.templates."vicinae-secret-settings" = mkIf (cfg.secretSettings != { }) {
      content = builtins.toJSON cfg.secretSettings;
    };

    xdg.configFile."vicinae/nix-settings.json" = mkIf (
      cfg.settings != { } || cfg.secretSettings != { }
    ) { source = nixSettingsFile; };

    xdg.dataFile = builtins.listToAttrs (
      map (ext: {
        name = "vicinae/extensions/${ext.name}";
        value.source = ext;
      }) cfg.extensions
    );

    # Deliberately NOT `xdg.configFile` for settings.json itself: that
    # symlinks into the Nix store (read-only), and Vicinae writes runtime
    # state back into this file when settings are edited from the GUI.
    # Materialize a real file that only imports `nix-settings.json` instead
    # (see gregnix.programs.terminal.tools.ssh's authorizedKeys for the same
    # pattern). Only done once (if missing or a stale symlink): the single
    # import entry here is permanently static regardless of what `settings`
    # / `secretSettings` are configured to -- see `nixSettingsFile` above,
    # which itself carries the conditional link to the sops-rendered
    # secretSettings file via its own nested `imports` key -- so there's
    # nothing here that would ever need to change on a later activation.
    home.activation.vicinaeSettingsStub = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      settingsPath="$HOME/.config/vicinae/settings.json"
      if [[ ! -e "$settingsPath" || -L "$settingsPath" ]]; then
        run install -d -m755 "$HOME/.config/vicinae"
        run rm -f "$settingsPath"
        echo '${builtins.toJSON { imports = [ "nix-settings.json" ]; }}' > "$settingsPath"
      fi
    '';
  };
}
