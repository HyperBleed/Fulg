{ config, inputs, lib, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Needed for 'nh'
  environment = {
    sessionVariables.FLAKE = "/home/${config.modules.users.userName}/Documents/Fulg";
    systemPackages = [
      pkgs.git # Flakes need this
      inputs.nh.packages.${pkgs.system}.default
    ];
  };

  # Faster rebuilds
  documentation = {
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
  };

  nix = {
    # Only the whell group can invoke nix commands
    allowedUsers = [ "@wheel" ];

    # Make rebuilds a lower priority
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 5;

    # Garbage collection
    gc = {
      automatic = true;
      dates = "Sunday *-*-* 04:00";
      options = "--delete-older-than 3d";
    };

    # Optimise store
    optimise = {
      automatic = true;
      dates = [ "04:00" ];
    };

    # Registry
    registry = lib.mapAttrs (_: v: { flake = v; }) inputs;
    nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    settings = {
      # Enable flakes
      experimental-features = [ "nix-command" "flakes" "cgroups" ];

      # Accept nix flakes by default
      accept-flake-config = true;

      # Build inside cgroups
      use-cgroups = true;

      # Registry again
      flake-registry = "/etc/nix/registry.json";

      # Build in sandbox
      sandbox = true;

      # Stop telling me it is dirty IK
      warn-dirty = false;

      # Show me more logs
      log-lines = 40;

      # Parallel TCP connections
      # '0' means as many as it wants
      http-connections = 0;

      trusted-users = [ "root" "@wheel" ];

      # substituters, we are not on Gentoo to compile everything
      builders-use-substitutes = true;
      substituters = [
        "https://cache.nixos.org?priority=10" # High prio
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://anyrun.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
      ];
    };
  };

  # Don't autoupdate
  system.autoUpgrade.enable = false;

  # Change this if you know what you are doing
  system.stateVersion = "24.05";
}