{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          rustToolchain = (pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml).override {
            targets = [ "wasm32-unknown-unknown" ];
          };
          nativeBuildInputs = with pkgs; [ rustToolchain pkg-config ];
          buildInputs = with pkgs; [ 
	    openssl 
	  ];
        in
        with pkgs;
        {

          packages = {
            default = rustPlatform.buildRustPackage rec {
              pname = "pg-trunk";
              version = "0.12.26";

	      unpackPhase = ''
	        ls
		pwd
	      '';

	      src = ./.;
            
              cargoHash = "sha256-T+RcZAAkervLSVC5Wf/hhEzoGyAsrL2bdS4wfbemEKI=";
            
              meta = with lib; {
                description = "postgres package manager";
                homepage = "https://github.com/tembo-io/trunk";
                license = licenses.postgresql;
                maintainers = [];
              };
            };
	  };

          #devShells.default = mkShell {
          #  inherit buildInputs nativeBuildInputs;
          #  shellHook = ''
          #    export PATH="''${PATH}:''${HOME}/.cargo/bin"
          #  '';
          #  };
        }
      );

}
