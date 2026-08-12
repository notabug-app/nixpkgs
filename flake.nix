{
  description = "Raspberry Pi Flake Drop-in Replacement with Custom Kernel and Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cf.url = "git+ssh://git@github.com/notabug-app/cf.git";
    void.url = "git+ssh://git@github.com/notabug-app/void.git";
    firn.url = "git+ssh://git@github.com/notabug-app/firn.git";

    nvmd-rpi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
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
      customOverlay =
        final: prev:
        (import ./pkgs.nix { inherit final prev inputs; })
        // (import ./linux.nix { inherit final prev inputs; });
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      overlays.default = customOverlay;

      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = self.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              (pkgs.callPackage ./devshells/update-vaultwarden.nix { })
              (pkgs.callPackage ./devshells/update-kernel.nix { })
              (pkgs.callPackage ./devshells/setup-attic.nix { })
              (pkgs.callPackage ./devshells/push-to-attic.nix { })
              (pkgs.callPackage ./devshells/record-store-paths.nix { })
              (pkgs.callPackage ./devshells/commit-update.nix { })
              (pkgs.callPackage ./devshells/generate-matrix.nix { })
            ];
          };
        }
      );

      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = self.legacyPackages.${system};
        in
        {
          cf = pkgs.cf;
          void = pkgs.void;
          firn = pkgs.firn;
          vaultwarden = pkgs.vaultwarden;
          vaultwarden-vault = pkgs.vaultwarden-vault;
        }
        // nixpkgs.lib.optionalAttrs (system == "aarch64-linux") {
          kernel-rpi4 = pkgs.linuxPackages_rpi4_7_1.kernel;
          cpupower-rpi4 = pkgs.linuxPackages_rpi4_7_1.cpupower;
          kernel-rpi5 = pkgs.linuxPackages_rpi5_7_1.kernel;
          cpupower-rpi5 = pkgs.linuxPackages_rpi5_7_1.cpupower;
          libraspberrypi = pkgs.libraspberrypi;
          raspberrypi-utils = pkgs.raspberrypi-utils;
        }
      );

      legacyPackages = nixpkgs.lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ customOverlay ];
        }
      );

      lib = nixos-raspberrypi.lib;

      nixosModules = nixos-raspberrypi.nixosModules // {
        cf = inputs.cf.nixosModules.default;
        void = inputs.void.nixosModules.default;
        firn = inputs.firn.nixosModules.default;

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
      };
    };
}
