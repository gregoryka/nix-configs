{
  age,
  buildGoModule,
  lib,
  ...
}:
# Reference plugin for age's ML-KEM-768 + P-256 hybrid "tag" recipients
# (age1tagpq1...), which age-plugin-se's `--pq` keygen produces. Not
# packaged anywhere (nixpkgs, NUR); it lives in filippo.io/age's own repo
# under extra/age-plugin-tagpq, same module as `pkgs.age` itself, so src
# and vendorHash are reused directly from it rather than pinned separately
# -- this tracks whatever `age` version nixpkgs ships automatically.
# sops's own age support only recognizes the bare `age1pq1` prefix
# natively; anything else shaped like a plugin recipient (age1tagpq1
# included) it execs `age-plugin-<name>` for -- this plugin is what makes
# that exec succeed instead of erroring "plugin not found".
buildGoModule {
  pname = "age-plugin-tagpq";
  inherit (age) version src vendorHash;
  subPackages = [ "extra/age-plugin-tagpq" ];
  meta = {
    description = "Reference age plugin for ML-KEM-768 + P-256 post-quantum hybrid tagged recipients";
    homepage = "https://github.com/FiloSottile/age";
    license = lib.licenses.bsd3;
    mainProgram = "age-plugin-tagpq";
  };
}
