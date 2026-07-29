{ pkgs, ... }: {
  gregnix.nix.useLix = true;
  gregnix.system.fonts.enable = true;
  gregnix.archetypes.work.enable = true;

  # Personal utilities that were already installed via Homebrew manually on
  # this machine, before `homebrew.onActivation.cleanup` (previously
  # "uninstall") started removing anything not declared here. Declaring them
  # keeps them tracked instead of removed. All four auto-update themselves in
  # place, same as `claude` in the work archetype, so greedy is off for the
  # same reason (see modules/darwin/tools/homebrew).
  homebrew.casks = [
    {
      name = "1password";
      greedy = false;
    }
    {
      name = "alt-tab";
      greedy = false;
    }
    {
      name = "beyond-compare";
      greedy = false;
    }
    {
      name = "google-drive";
      greedy = false;
    }
  ];

  # Corporate network TLS inspection (Zscaler) re-signs HTTPS traffic with a
  # private root CA that Lix's bundled nss-cacert store doesn't trust,
  # breaking substituter/flake-input fetches. nix-darwin's security.pki
  # module merges this into /etc/ssl/certs/ca-certificates.crt and points
  # NIX_SSL_CERT_FILE at it (which nix-daemon.nix forwards into the daemon's
  # own environment), so both the nix CLI and the daemon trust it.
  #
  # pkgs.zscaler-cacert tracks Zscaler's published root CA (from
  # keyserver.dhl.com/certificates) -- confirmed (via the live cert chain on
  # cache.nixos.org) to be the same key currently signing this org's
  # intercepted traffic, so no local copy needs to be hand-maintained here.
  # NOTE: this can't bootstrap a brand new machine's *first* activation --
  # see README.md for that.
  security.pki.certificateFiles = [
    "${pkgs.zscaler-cacert}/etc/ssl/certs/zscaler-ca.crt"
  ];

  # Determinate Nix has been uninstalled and Lix is now installed in its
  # place, so nix-darwin can manage nix/nix-daemon itself again.
  nix.enable = true;

  # Back up any pre-existing dotfiles home-manager would otherwise refuse to
  # overwrite (e.g. from a prior manual/Homebrew install) instead of blocking
  # activation.
  home-manager.backupFileExtension = "hm-backup";

  system.primaryUser = "gregory.kanter";
  system.stateVersion = 7;
}
