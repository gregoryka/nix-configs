{
  description = "Private inputs for development purposes. These are used by the top level flake in the `dev` partition, but do not appear in consumers' lock files.";

  inputs = {
    # By pointing to the parent directory, this flake can "follow" the inputs
    # of the root flake, ensuring dependency versions are kept in sync.
    root = {
      url = "path:./../..";
    };

    nixpkgs.follows = "root/nixpkgs";
    flake-parts.follows = "root/flake-parts";
    home-manager.follows = "root/home-manager";
    nix-darwin.follows = "root/nix-darwin";
    nur.follows = "root/nur";
    sops-nix.follows = "root/sops-nix";

    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # This flake is only used for its inputs.
  outputs = _inputs: { };
}
