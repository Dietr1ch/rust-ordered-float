{
  description = "A playground for heuristic search algorithms";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                rust-overlay.overlays.default
                self.overlays.default
              ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        rustToolchain = prev.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      };

      devShells = forEachSupportedSystem (
        { pkgs }:
        {
          default = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              rustToolchain

              rustc
              cargo
              rustup
            ];

            packages = with pkgs; [
              hunspell
              hunspellDicts.en_GB-large

              cargo-audit
              cargo-deny
              cargo-edit
              cargo-outdated
              cargo-valgrind
              cargo-watch

              bacon
            ];

            env = {
              # Bevy (https://github.com/bevyengine/bevy/blob/main/docs/linux_dependencies.md#nix)
              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;

              # Spelling
              DICTIONARY = "en_GB";
              DICPATH = "${pkgs.hunspell}/bin/hunspell";

              # Rust
              ## Required by rust-analyzer
              RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
            };
          };
        }
      );
    };
}
