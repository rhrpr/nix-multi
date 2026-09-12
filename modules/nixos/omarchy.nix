{
  lib,
  username,
  useremail,
  isVM,
  ...
}:

# ---------------------------------------------------------------------------
# Omarchy NixOS system module
#
# Responsibility split:
#   THIS FILE  — system-level wiring: packages, services, autologin, groups,
#                session variables.  Delegates to omarchy-nix for the heavy
#                NixOS plumbing.
#
#   home/linux/omarchy.nix — dotfiles symlinked directly from the upstream
#                            omacom/omarchy flake input, so `nix flake update
#                            omarchy` always reflects the latest upstream config.
# ---------------------------------------------------------------------------
{
  # The omarchy-nix module provides the actual upstream Omarchy Quattro
  # desktop, adapted for declarative NixOS package management.
  omarchy = {
    enable = true;
    full_name = username;
    email_address = useremail;
    timezone = "Europe/London";
    terminal = "foot";
    scale = 1;

    managedPackagesFile =
      if builtins.pathExists ../../omarchy-packages.json then ../../omarchy-packages.json else null;

    # The VM already authenticates through its host/disk boundary and has
    # historically auto-logged in. Physical hosts retain the SDDM prompt.
    autologin.user = if isVM then username else null;
  };

  # Omarchy uses these groups for input automation, display brightness, and
  # the Quickshell desktop services. Existing groups remain additive.
  users.users.${username}.extraGroups = [
    "input"
    "ydotool"
    "i2c"
  ];

  # Omarchy's Nix-native Install/Remove and Update actions need to know which
  # consumer flake to edit and rebuild.
  environment.sessionVariables.OMARCHY_NIX_FLAKE = "/home/${username}/.config/nix-multi";

  # Bluetooth is deliberately disabled by the VM module. Document that as an
  # expected override of Omarchy's physical-desktop default.
  warnings = lib.optional isVM "Omarchy VM profile: Bluetooth remains disabled; GPU passthrough is recommended for Quickshell.";
}
