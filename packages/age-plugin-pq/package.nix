{
  age,
  buildGoModule,
  lib,
  ...
}:
# Compatibility plugin for age's ML-KEM-768 + X25519 hybrid post-quantum
# recipients/identities (age1pq1..., AGE-SECRET-KEY-PQ-1...). `rage`
# doesn't gain native pq support until 0.13 (still unreleased); until
# then, this plugin lets rage/sops use pq identities via
# `age-plugin-pq -identity`. Lives in the same filippo.io/age repo as
# age-plugin-tagpq, hence the same src/vendorHash reuse.
buildGoModule {
  pname = "age-plugin-pq";
  inherit (age) version src vendorHash;
  subPackages = [ "extra/age-plugin-pq" ];
  meta = {
    description = "Compatibility plugin for age's ML-KEM-768 + X25519 post-quantum hybrid recipients";
    homepage = "https://github.com/FiloSottile/age";
    license = lib.licenses.bsd3;
    mainProgram = "age-plugin-pq";
  };
}
