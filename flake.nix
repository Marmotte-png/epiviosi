{
  description = "EPIVÍOSI OS — système live hors-ligne basé sur NixOS (x86_64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Modules réutilisables (les dépôts frères pourront s'y brancher).
      nixosModules.default = import ./modules;

      nixosConfigurations.epiviosi-live = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/live-iso.nix
          { nixpkgs.overlays = [ self.overlays.default ]; }
        ];
      };

      overlays.default = final: prev: {
        epiviosi-persist = final.callPackage ./pkgs/epiviosi-persist { };
        epiviosi-artwork = final.callPackage ./pkgs/epiviosi-artwork { };
      };

      packages.${system} = {
        iso = self.nixosConfigurations.epiviosi-live.config.system.build.isoImage;
        default = self.packages.${system}.iso;
        epiviosi-persist = pkgs.callPackage ./pkgs/epiviosi-persist { };
        epiviosi-artwork = pkgs.callPackage ./pkgs/epiviosi-artwork { };
      };

      checks.${system} = {
        epiviosi-persist = self.packages.${system}.epiviosi-persist;
        # Évalue la configuration complète (toplevel) sans construire l'ISO.
        toplevel = self.nixosConfigurations.epiviosi-live.config.system.build.toplevel;
      };
    };
}
