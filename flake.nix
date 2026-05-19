{
  description = "nixglass — NixOS + Niri + Noctalia config (migration from Omarchy)";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Niri scrolling tiling compositor. We pin to niri-flake HEAD; the actual
    # niri package is overridden to `niri-unstable` in nixos/configuration.nix
    # so we get ext-background-effect (blur protocol) support — stable v25.08
    # doesn't have it.
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";
    niri.inputs.nixpkgs-stable.follows = "nixpkgs";

    # Ghostty from upstream. nixpkgs ships v1.3.1, which was tagged
    # 2026-03-13 — four days BEFORE commit 9e2e99c added the
    # ext-background-effect-v1 protocol bindings that let niri actually blur
    # the surface behind ghostty. Using upstream's flake gets us a 1.3.2-dev
    # build that includes the protocol.
    ghostty.url = "github:ghostty-org/ghostty";
    ghostty.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # Noctalia desktop shell — bar, launcher, notifications, theming engine
    noctalia.url = "github:noctalia-dev/noctalia-shell";
    noctalia.inputs.nixpkgs.follows = "nixpkgs";

    # Zen browser — community flake; not in nixpkgs.
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#nixglass'
    nixosConfigurations = {
      nixglass = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          inputs.niri.nixosModules.niri
          inputs.home-manager.nixosModules.home-manager
          {
            # Not useGlobalPkgs — home.nix declares its own nixpkgs overlays/config,
            # which is also what the standalone home-manager entrypoint relies on.
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.ihsen = import ./home-manager/home.nix;
            # Move conflicting pre-existing files to *.backup instead of failing
            # activation. Mostly matters for files apps write at runtime that we
            # later start declaring (e.g. ~/.config/mimeapps.list).
            home-manager.backupFileExtension = "backup";
          }
          # > Our main nixos configuration file <
          ./nixos/configuration.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#ihsen@nixglass'
    homeConfigurations = {
      "ihsen@nixglass" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs;};
        modules = [
          # > Our main home-manager configuration file <
          ./home-manager/home.nix
        ];
      };
    };
  };
}
