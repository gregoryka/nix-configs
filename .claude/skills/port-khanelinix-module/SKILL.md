---
name: port-khanelinix-module
description: Port a khanelinix module into this repo's minimal gregnix module tree, stripped of personalization and out-of-scope content, then wire it up and verify it builds. Use when the user asks to "add <thing> module" or "add <program>" and a matching module likely exists in khanelinix.
---

# Port a khanelinix module

khanelinix (`/Users/gregory.kanter/gitrepos/khanelinix`, readable via this
project's `.claude/settings.json`) is the upstream source for this repo's
nix-darwin/home-manager modules. When asked to add a module or program,
port the matching khanelinix module rather than writing one from scratch.

## Steps

1. **Find it.** Search khanelinix for the matching module, e.g.:
   `find /Users/gregory.kanter/gitrepos/khanelinix/modules -type d -iname "*<name>*"`
   Check both `modules/home/...` and a darwin-specific counterpart under
   `modules/darwin/...` if one exists.

   **If nothing matches** (e.g. the user asks for "starship" but khanelinix
   uses oh-my-posh instead, so no starship module exists there), don't
   force-fit an unrelated module. Write a fresh minimal module in the same
   house style instead: `options.gregnix.programs.terminal.tools.<name>.enable
   = lib.mkEnableOption "<name>";` gating a `config = lib.mkIf cfg.enable {
   programs.<name>.enable = true; ... };` block, with the smallest reasonable
   defaults — usually just `enable` plus one or two relevant shell
   integration flags, nothing elaborate. Same "smallest version that
   provides the feature" bar as a ported module gets in step 3.

2. **Read it fully** before deciding what to keep.

3. **Strip to minimal.** Default to the smallest version that provides the
   feature, dropping:
   - `khanelinix`/`khaneliman` identity strings, emails, hostnames.
   - Linux-only or window-manager-specific config (anything gated on
     `isLinux`, or referencing options like `programs.graphical.wms.*` that
     don't exist in this repo).
   - sops-nix / secrets wiring — this repo has no sops integration yet.
   - Custom darwin-only infra (hand-rolled launchd daemons, log-rotation
     modules) **when the underlying home-manager module already wires the
     same thing natively**. Verify this by grepping the pinned home-manager
     module source before assuming custom infra is required, e.g.:
     `find $(nix flake prefetch --json 'github:nix-community/home-manager/<rev>' | python3 -c "import json,sys;print(json.load(sys.stdin)['storePath'])") -iname "*<name>*"`
     then grep it for `launchd`/`systemd` to see what it already sets up.
   - Elaborate settings/plugin lists not explicitly requested — a bare
     `enable = true;` plus one or two integration flags is usually enough;
     add more only if asked.

   **Don't copy option values that depend on khanelinix customizations we
   didn't port.** Before copying a khanelinix option value verbatim, check
   whether its correctness depends on something *else* in khanelinix that
   we deliberately dropped. Concrete example: khanelinix's fzf module sets
   `enableZshIntegration = false` — that only works there because
   khanelinix's own zsh module manually sources the fzf shell hook
   (`source <(fzf --zsh)`) elsewhere. This repo's trimmed-down zsh module
   dropped that manual sourcing, so blindly copying `enableZshIntegration =
   false` would silently leave fzf's keybindings non-functional; it had to
   flip to `true` so home-manager's own fzf module wires the integration
   instead. General rule: when an option value looks like it's
   disabling/delegating something (integration flags, "let X handle this
   instead" patterns), grep the rest of khanelinix — at least the
   immediately-related sibling modules, e.g. zsh/shell modules for
   shell-integration flags — to confirm the thing it delegates to was
   actually also ported. If not, the value likely needs to flip.

4. **Rename the namespace.** `khanelinix` → `gregnix` throughout the new
   file(s) only (e.g. `sed -i '' 's/khanelinix/gregnix/g' <new files>`).
   Never touch the khanelinix source repo itself. (Skip this step for a
   freshly-written module from step 1 — write it with the `gregnix`
   namespace directly.)

5. **Place it** under the matching path in this repo (`modules/darwin/...`
   or `modules/home/...`), mirroring khanelinix's directory structure so
   future comparisons/diffs against khanelinix stay easy.

6. **Enable it** under the `gregnix.*` namespace in the relevant file:
   - System-level (darwin): `systems/aarch64-darwin/<host>/default.nix`
   - User-level (home-manager): `homes/aarch64-darwin/<user>@<host>/default.nix`

7. **Stage it:** `git add -A -- <changed paths>`. Required — this flake is
   git-tracked and untracked files are invisible to `nix flake` evaluation.

8. **Verify, in this order — dry-run alone is not enough:**
   - `nix eval '.#homeConfigurations."<user>@<host>".config.<resolved.option>'`
     (or the darwin-config equivalent) to confirm the option actually took
     effect.
   - `nix flake check --no-build` to confirm the whole flake still
     evaluates with no regressions.
   - An actual (non-dry-run) `nix build` of the relevant
     `activationPackage`/`system` output. Dry-run builds can hide errors
     that only surface on real derivation realization.

   **If the option renders into a generated file** (e.g. `homebrew.casks`
   templating into a `Brewfile`, or any other option whose effect is a
   rendered config file rather than a direct runtime value), `nix eval` on
   the option alone isn't sufficient proof — the eval'd list can look
   correct while the templated/merged output differs (wrong token,
   unexpected merge from another module). Build the specific output
   derivation and inspect its actual rendered content: find its `.drv` path
   in the `nix build` output above (or via
   `nix path-info --derivation '.#darwinConfigurations.<host>.system'`),
   then `nix build <path-to-that-.drv> --no-link --print-out-paths | xargs
   cat`. Confirmed case: `homebrew.casks = ["claude" "claude-code"]`
   verified correct by building the `Brewfile.drv` from the system build's
   dependency list and confirming its text was exactly `cask "claude",
   greedy: true, trusted: true` / `cask "claude-code", ...` — nothing
   extraneous, even though an incidental `mas` package also appeared in the
   build (unrelated nix-darwin homebrew-module dependency, not a sign of a
   stray option).

   **If you need to check whether a package exists before referencing it**
   (e.g. confirming `pkgs.nerd-fonts.symbols-only` is a real attribute),
   `nix eval '.#legacyPackages.<system>...'` against THIS flake is **not**
   usable — flake-parts doesn't auto-populate `legacyPackages` here, so it
   silently resolves to an empty attrset and any `hasAttr`/attr-path check
   against it just comes back `false`/missing, which looks like "package
   doesn't exist" but actually means "wrong pkgs source." Instead, import
   the flake's actual pinned nixpkgs directly:
   1. Get the locked revision:
      `nix flake metadata --json | python3 -c "import json,sys; d=json.load(sys.stdin); n=d['locks']['nodes']['nixpkgs']['locked']; print(f\"github:{n['owner']}/{n['repo']}/{n['rev']}\")"`
   2. Import and check:
      `nix eval --impure --expr 'let pkgs = import (builtins.getFlake "<rev from step 1>") { system = "aarch64-darwin"; }; in pkgs.<attr path>.pname'`

9. **Report back concisely:** what was ported, what was deliberately
   dropped and why, and confirmation that all three verification steps
   passed.
