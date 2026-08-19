{
  stdenv,
  lib,
  qodo-cli,
  ...
}:
let
  # Kept in sync manually with the actual bundle (run `qodo skills list`
  # after bumping the version pin in ../qodo-cli/package.nix and update
  # this list if it changed) rather than discovered via `builtins.readDir`
  # on the built output: that would be import-from-derivation, forcing a
  # build during evaluation just to answer e.g. "is qodo enabled?" --
  # which also breaks cross-system eval (an aarch64-darwin machine can't
  # build the x86_64-linux derivation just to list its contents).
  # Consumers (claude-code/devin tool modules) get this from
  # `passthru.skillNames` so it's declared once, alongside the package
  # that actually produces the matching directories.
  skillNames = [
    "qodo-codebase-wisdom"
    "qodo-get-rules"
    "qodo-manage-standards"
    "qodo-review"
    "qodo-review-resolver"
  ];
in
# Qodo's agent skills aren't shipped as loose files in the release artifact
# -- they're bundled as string literals inside qodo.mjs and only ever
# materialize on disk via `qodo skills install`. That subcommand is itself
# fully offline (verified: no network call, no login -- it just detects
# `~/.claude`/`~/.config/devin` and writes the bundled markdown into them),
# so running it once here at build time, into a throwaway $HOME, turns the
# bundle's skills into normal Nix-built directories -- one subdirectory per
# skill (named per `skillNames` above) -- that the gregnix claude-code/devin
# tool modules consume directly by name. Content is identical between the
# two outputs (verified: `diff -rq` on a built pair is empty) -- only the
# destination directory differs, so one `skills install` run covers both.
# `out` is required as an output name -- without it, stdenv's
# multiple-outputs setup hook fails looking for a `dev`/`out` output to
# assign its own bookkeeping variable to -- but is otherwise unused; always
# reference `.claudeCode`/`.devin` explicitly rather than the implicit
# default output.
stdenv.mkDerivation {
  pname = "qodo-cli-skills";
  inherit (qodo-cli) version;

  outputs = [
    "out"
    "claudeCode"
    "devin"
  ];

  # Space-separated for the buildPhase's drift check below; every top-level
  # attribute here becomes a build-time env var.
  expectedSkillNames = lib.concatStringsSep " " skillNames;

  dontUnpack = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME/.claude" "$HOME/.config/devin"
    "${lib.getExe qodo-cli}" skills install --agent claude-code,devin --global

    # Catch drift between the hardcoded `skillNames` above and what
    # upstream actually bundled -- loudly, at build time, rather than
    # silently missing a renamed/added skill or failing obscurely later
    # when a tool module references a name that doesn't exist.
    actual="$(ls "$HOME/.claude/skills" | sort)"
    expected="$(printf '%s\n' $expectedSkillNames | sort)"
    if [ "$actual" != "$expected" ]; then
      echo "qodo-cli-skills: bundled skill names no longer match the hardcoded" >&2
      echo "list in package.nix -- update \`skillNames\` there to match:" >&2
      echo "  expected: $expected" >&2
      echo "  actual:   $actual" >&2
      exit 1
    fi

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    touch "$out"
    cp -r "$HOME/.claude/skills" "$claudeCode"
    cp -r "$HOME/.config/devin/skills" "$devin"
    runHook postInstall
  '';

  passthru = { inherit skillNames; };

  meta = {
    description = "Qodo's bundled agent skills, extracted from qodo-cli at build time (one output per supported coding agent)";
  };
}
