{
  description = "Raspberry Pi Flake Drop-in Replacement with Custom Kernel and Packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-raspberrypi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cf-ddns.url = "git+ssh://git@github.com/notabug-app/cf-ddns.git";
    dnsr.url = "git+ssh://git@github.com/notabug-app/dnsr.git";
    rpi-vcio.url = "git+ssh://git@github.com/notabug-app/rpi-vcio.git";

    nvmd-rpi = {
      url = "github:nvmd/nixos-raspberrypi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vaultwarden-src = {
      url = "github:dani-garcia/vaultwarden/1.37.0";
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
      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = self.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            nativeBuildInputs = [
              (pkgs.callPackage ./devshells/update-vaultwarden.nix { })
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
          cf-ddns = pkgs.cf-ddns;
          dnsr = pkgs.dnsr;
          rpi-vcio = pkgs.rpi-vcio;
          vaultwarden = pkgs.vaultwarden;
          vaultwarden-vault = pkgs.vaultwarden-vault;
        }
        // nixpkgs.lib.optionalAttrs (system == "aarch64-linux") {
          kernel = pkgs.linuxPackages_rpi_7_1.kernel;
          cpupower = pkgs.linuxPackages_rpi_7_1.cpupower;
          libraspberrypi = pkgs.libraspberrypi;
        }
      );

      legacyPackages = nixpkgs.lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ customOverlay ];
        }
      );

      overlays.default = customOverlay;

      nixosModules = {
        cf-ddns = inputs.cf-ddns.nixosModules.default;
        dnsr = inputs.dnsr.nixosModules.default;

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
              inputs.cf-ddns.nixosModules.default
              inputs.dnsr.nixosModules.default
            ];

            nixpkgs.overlays = [ customOverlay ];

            boot.kernelPackages = lib.mkMerge [
              (lib.mkIf (config.raspberry-pi-nix.board == "bcm2711") pkgs.linuxPackages_rpi_7_1)
              (lib.mkIf (config.raspberry-pi-nix.board == "bcm2712") pkgs.linuxPackages_rpi_7_1)
            ];

            assertions = [
              {
                assertion = builtins.elem config.raspberry-pi-nix.board [
                  "bcm2711"
                  "bcm2712"
                ];
                message = "This custom flake only keeps Pi 4 (bcm2711) and Pi 5 (bcm2712) enabled.";
              }
            ];
          };
      };
    };
}
