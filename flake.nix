{
  description = "Raspberry Pi Flake Drop-in Replacement with Custom Kernel and Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cf = {
      url = "git+ssh://git@github.com/notabug-app/cf.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    void = {
      url = "git+ssh://git@github.com/notabug-app/void.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firn = {
      url = "git+ssh://git@github.com/notabug-app/firn.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helium = {
      url = "git+ssh://git@github.com/s-Sizz/helium.git";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };
    vaultwarden-src = {
      url = "github:dani-garcia/vaultwarden/1.37.1";
      flake = false;
    };
    webvault-src = {
      url = "https://github.com/dani-garcia/bw_web_builds/releases/download/v2026.6.4/bw_web_v2026.6.4.tar.gz";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-raspberrypi,
      ...
    }@inputs:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      customOverlay =
        final: prev:
        (import ./pkgs.nix { inherit final prev inputs; })
        // (if prev.stdenv.hostPlatform.system == "aarch64-linux"
            then (import ./linux.nix { inherit final prev inputs; })
            else { });
    in
    {
      overlays = {
        default = customOverlay;
        x86_64-linux = final: prev: import ./pkgs.nix { inherit final prev inputs; };
        aarch64-linux = final: prev: (import ./pkgs.nix { inherit final prev inputs; }) // (import ./linux.nix { inherit final prev inputs; });
      };

      devShells = forAllSystems (system:
        let pkgs = self.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              (pkgs.callPackage ./devshells/update-vaultwarden.nix { })
              (pkgs.callPackage ./devshells/update-helium.nix { })
              (pkgs.callPackage ./devshells/update-kernel.nix { })
              (pkgs.callPackage ./devshells/setup-firn.nix { })
              (pkgs.callPackage ./devshells/commit-update.nix { })
            ];
          };
        }
      );

      packages = forAllSystems (system:
        let pkgs = self.legacyPackages.${system}; in {
          inherit (pkgs) cf void firn vaultwarden vaultwarden-vault;
        } // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) noctalia noctalia-greeter nvidia-legacy-580 helium;
        } // pkgs.lib.optionalAttrs (system == "aarch64-linux") {
          inherit (pkgs) kernel-rpi4 cpupower-rpi4 kernel-rpi5 cpupower-rpi5 libraspberrypi raspberrypi-utils;
        }
      );

      legacyPackages = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ customOverlay ];
          config.allowUnfree = true;
        }
      );

      lib = nixos-raspberrypi.lib;

      homeModules.noctalia = inputs.noctalia.homeModules.default;

      nixosModules = nixos-raspberrypi.nixosModules // {
        cf = inputs.cf.nixosModules.default;
        void = inputs.void.nixosModules.default;
        firn = inputs.firn.nixosModules.default;
        noctalia = inputs.noctalia.nixosModules.default;
        noctalia-greeter = inputs.noctalia-greeter.nixosModules.default;

        default =
          {
            pkgs,
            lib,
            config,
            ...
          }:
          {
            imports = [
              nixos-raspberrypi.nixosModules.default
              inputs.cf.nixosModules.default
              inputs.void.nixosModules.default
              inputs.firn.nixosModules.default
            ];

            nixpkgs.overlays = [ customOverlay ];

            boot.kernelPackages = lib.mkMerge [
              (lib.mkIf (config.boot.loader.raspberry-pi.variant == "4") (
                lib.mkForce pkgs.linuxPackages_rpi4_7_1
              ))
              (lib.mkIf (config.boot.loader.raspberry-pi.variant == "5") (
                lib.mkForce pkgs.linuxPackages_rpi5_7_1
              ))
            ];

            assertions = [
              {
                assertion = builtins.elem config.boot.loader.raspberry-pi.variant [
                  "4"
                  "5"
                ];
                message = "This custom flake only keeps Pi 4 and Pi 5 enabled.";
              }
            ];
          };

        x86_64-linux = 
          { ... }: 
          {
            imports = [
              inputs.cf.nixosModules.default
              inputs.void.nixosModules.default
              inputs.firn.nixosModules.default
              inputs.noctalia.nixosModules.default
              inputs.noctalia-greeter.nixosModules.default
            ];
            nixpkgs.overlays = [ customOverlay ];
          };
      };
    };
}
