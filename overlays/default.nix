# This file defines overlays
# These are arbitrary named and just some conventions I use, you can name then whenever and/or make as many as you want
{inputs, ...}: let
  # Single source of truth for the unstable nixpkgs instance: shared by both
  # the `modifications` overlay (which inherits specific packages) and the
  # `unstable-packages` overlay (which exposes the whole set as `unstablePkgs`).
  # The openldap test patch belongs here so anything pulled from unstable —
  # whether via inherit or the escape-hatch — gets a buildable openldap when
  # lutris's dep tree drags it in.
  mkUnstable = system:
    import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (_uFinal: uPrev: {
          openldap = uPrev.openldap.overrideAttrs {doCheck = false;};
        })
      ];
    };
in {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # Inherit specific packages from unstable so consumers just write
  # `pkgs.lutris` and get the unstable build transparently. Add more
  # packages here as nixpkgs-25.11 lags upstream — drop them when stable
  # catches up.
  modifications = final: _prev: let
    unstable = mkUnstable final.stdenv.hostPlatform.system;
  in {
    inherit (unstable) claude-code gh lutris zellij mangowc quickshell;
  };

  # Escape hatch: exposes the entire unstable nixpkgs at `pkgs.unstablePkgs.*`
  # for ad-hoc use without committing to the `inherit` form. Kept around for
  # one-shot experiments; for anything that sticks, migrate it up to
  # `modifications` so the rest of the config doesn't need to know it's
  # coming from unstable.
  unstable-packages = final: _prev: {
    unstablePkgs = mkUnstable final.stdenv.hostPlatform.system;
  };
}
