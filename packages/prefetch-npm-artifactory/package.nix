{
  writeShellApplication,
  curl,
  jq,
  nix,
  _1password-cli,
  ...
}:
writeShellApplication {
  name = "prefetch-npm-artifactory";
  runtimeInputs = [
    curl
    jq
    nix
    _1password-cli
  ];
  text = ''
    # Pre-fetches every npm tarball a package-lock.json resolves to
    # registry.npmjs.org through Artifactory (bypassing the org's block on
    # npmjs.org directly) and registers each one into the Nix store at the
    # exact fixed-output path `fetchurl`/`importNpmLock` expects, keyed by
    # the lockfile's `integrity` hash. Once run, a *pure* `darwin-rebuild
    # switch` (no --impure, no secrets, no Artifactory awareness in Nix)
    # finds those content-addressed paths already present and never has to
    # fetch them itself.
    #
    # Artifactory's npm proxy mirrors the upstream registry's URL layout
    # under its own base path, so a tarball's Artifactory URL is just its
    # `resolved` URL with the "https://registry.npmjs.org/" prefix swapped
    # for the registry from `~/.npmrc` (managed by
    # gregnix.programs.terminal.tools.npm). Auth is the same Bearer-token
    # scheme npm itself sends for a registry's `_authToken`; the real token
    # value comes from 1Password, injected once below via a single `op run`
    # re-exec (never per-request).
    #
    # Usage: prefetch-npm-artifactory <url-to-package-lock.json>

    ARTIFACTORY_NPM_TOKEN_REF="''${ARTIFACTORY_NPM_TOKEN_REF:-op://Employee/global-artifactory-npm-token/credential}"

    if [[ -z "''${_OP_RUN_ACTIVE:-}" ]]; then
      export _OP_RUN_ACTIVE=1
      exec env "ARTIFACTORY_NPM_TOKEN=$ARTIFACTORY_NPM_TOKEN_REF" op run --no-masking -- "$0" "$@"
    fi

    package_lock_url="''${1:?usage: prefetch-npm-artifactory <url-to-package-lock.json>}"
    registry="$(sed -n 's/^registry=//p' "$HOME/.npmrc")"
    registry="''${registry%/}"

    workdir="$(mktemp -d)"
    trap 'rm -rf "$workdir"' EXIT

    curl -fsSL "$package_lock_url" -o "$workdir/package-lock.json"

    entries="$(jq -r '
      [.packages[]
        | select(.resolved != null and (.resolved | startswith("https://registry.npmjs.org/")) and .integrity != null)
        | {resolved, integrity}]
      | unique_by(.resolved)
      | .[] | [.resolved, .integrity] | @tsv
    ' "$workdir/package-lock.json")"
    count="$(grep -c . <<< "$entries" || true)"

    # Lockfiles can list hundreds of tarballs; fetch them concurrently
    # rather than one curl+add-fixed round-trip at a time.
    fetch_one() {
      local resolved="$1" integrity="$2"
      local target_file
      target_file="$workdir/$(basename "$resolved")"
      curl -fsSL \
        -H "Authorization: Bearer $ARTIFACTORY_NPM_TOKEN" \
        "$registry/''${resolved#https://registry.npmjs.org/}" \
        -o "$target_file"

      local store_path
      store_path="$(nix-store --add-fixed "''${integrity%%-*}" "$target_file")"
      echo "+ $(basename "$resolved") -> $store_path"
    }
    export -f fetch_one
    export ARTIFACTORY_NPM_TOKEN registry workdir

    # shellcheck disable=SC2016 # $1/$2 are meant to expand in the child bash, not here
    xargs -L1 -P8 bash -c 'fetch_one "$1" "$2"' bash <<< "$entries"

    echo "Registered $count tarball(s); a pure darwin-rebuild switch should now build anything depending on this lockfile without network access."
  '';
  meta = {
    description = "Pre-fetches a package-lock.json's npm tarballs through Artifactory and registers them into the Nix store, so a later pure build needs no network access for them";
    mainProgram = "prefetch-npm-artifactory";
  };
}
