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
	  nativeBuildInputs = with pkgs; [
	    rustToolchain
	    pkg-config
	    postgresql
	    rustPlatform.cargoCheckHook
	  ];
          buildInputs = with pkgs; [ 
	    openssl 
	    postgresql
	  ];
        in
        with pkgs;
        {
	  overlays = {
            default =  final: prev: {
              pg-trunk = rustPlatform.buildRustPackage rec {
                inherit buildInputs nativeBuildInputs;
                pname = "pg-trunk";
                version = "0.12.26";

                src = ./cli;

                cargoHash = "sha256-w71MC1XHbFRPnjS6pOm21pHVwO5lxpfFH++gs/Yefvc=";

                checkType = "debug";

                doCheck = false;

                cargoCheckFeatures = ["ignore-network-related-tests"];

                meta = with lib; {
                  description = "postgres package manager";
                  homepage = "https://github.com/tembo-io/trunk";
                  license = licenses.postgresql;
                  maintainers = [];
                };
              };
            };
          };

          packages = {
            default = rustPlatform.buildRustPackage rec {
	      inherit buildInputs nativeBuildInputs;
              pname = "pg-trunk";
              version = "0.12.26";

	      src = ./cli;
            
	      cargoHash = "sha256-w71MC1XHbFRPnjS6pOm21pHVwO5lxpfFH++gs/Yefvc=";

	      checkType = "debug";

	      doCheck = false;

	      cargoCheckFeatures = ["ignore-network-related-tests"];

              meta = with lib; {
                description = "postgres package manager";
                homepage = "https://github.com/tembo-io/trunk";
                license = licenses.postgresql;
                maintainers = [];
              };
            };
	  };

          apps = {
            default = {
              type = "app";
              program = "${self.packages.${system}.default}/bin/trunk";
            };
          };

          devShells.default = mkShell {
            inherit buildInputs nativeBuildInputs;
            #shellHook = ''
            #  export PATH="''${PATH}:''${HOME}/.cargo/bin"
            #'';
          };

	  nixosModules = {
            default = { config, pkgs, ... }: {
              nixpkgs.overlays = [ (import self) ];
              environment.systemPackages = [ pkgs.pg-trunk ];
            };
          };
        }
      );

}
