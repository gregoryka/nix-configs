# GregNix

Personal nix-darwin + home-manager configuration, based on
[khanelinix](https://github.com/khaneliman/khanelinix).

## First-time activation on a new machine (corporate/Zscaler network)

`security.pki.certificateFiles` (see
`systems/aarch64-darwin/<hostname>/default.nix`) makes nix-darwin trust this
org's Zscaler TLS-inspection root **after** a successful activation -- but
getting to that first successful activation requires Nix to fetch this
flake's inputs (`nixpkgs`, `home-manager`, etc.) over HTTPS through that same
intercepted connection first. Lix/Nix's own bundled cacert store doesn't
trust Zscaler's root yet at this point, so the very first
`sudo darwin-rebuild switch --flake .` on a fresh machine will fail with TLS
errors unless one of the following is done first:

- **Bootstrap off a non-corporate network** (home wifi, phone hotspot, etc.)
  for the first activation only. Simplest option if available.
- **Point Nix at a manually-exported cert for the first run only**:
  ```sh
  security find-certificate -c "Zscaler Root CA" -p \
    /Library/Keychains/System.keychain > /tmp/zscaler-root-ca.pem
  sudo NIX_SSL_CERT_FILE=/tmp/zscaler-root-ca.pem \
    darwin-rebuild switch --flake .#<hostname>
  ```
  This exports whatever root your MDM profile already installed into the
  System keychain, and uses it just for this one bootstrap build. Every
  subsequent rebuild works normally, since by then
  `security.pki.certificateFiles` has already merged trust into
  `/etc/ssl/certs/ca-certificates.crt` and pointed `NIX_SSL_CERT_FILE` at it.

## First-time activation on a standalone Linux host (e.g. a dev VM)

Standalone `home-manager` (no NixOS underneath) never touches `/etc/passwd`,
so switching the login shell to the Nix-managed `zsh` is a one-time manual
step after the first `home-manager switch --flake .#<name>`:

```sh
# Use the ~/.nix-profile symlink, not its resolved store path -- the
# symlink target changes on every zsh update/generation switch, but the
# symlink itself is stable, so /etc/shells and `chsh` never need to be
# redone afterwards.
NIX_ZSH="$HOME/.nix-profile/bin/zsh"
grep -qxF "$NIX_ZSH" /etc/shells || echo "$NIX_ZSH" | sudo tee -a /etc/shells
chsh -s "$NIX_ZSH"
```

Log out and back in (or start a fresh login shell) afterwards for the change
to take effect.
