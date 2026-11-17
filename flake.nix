{
  description = "EPIVÍOSI OS — système live hors-ligne basé sur NixOS (x86_64)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    epiviosi-wiki = {
      url = "github:Marmotte-png/epiviosi-wiki";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    epiviosi-maps = {
      url = "github:Marmotte-png/epiviosi-maps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    epiviosi-security = {
      url = "github:Marmotte-png/epiviosi-security";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    epiviosi-medic = {
      url = "github:Marmotte-png/epiviosi-medic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, epiviosi-wiki, epiviosi-maps, epiviosi-security, epiviosi-medic, ... }:
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
          epiviosi-wiki.nixosModules.default
          epiviosi-maps.nixosModules.default
          epiviosi-security.nixosModules.default
          epiviosi-medic.nixosModules.default
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
        # Préparation d'une clé : ISO + wiki + persistance (table MBR).
        cle-usb = import ./tests/cle-usb.nix {
          inherit pkgs;
          iso = "${self.packages.${system}.iso}/iso/epiviosi-live-x86_64.iso";
          tools = [
            self.packages.${system}.epiviosi-persist
            epiviosi-wiki.packages.${system}.epiviosi-wiki-setup
          ];
        };
      };
    };
}
