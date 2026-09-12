{
  username,
  pkgs,
  lib,
  desktopManager ? "end4",
  isDarwin ? false,
  isLinux ? false,
  ...
}:

let
  isOmarchy = desktopManager == "omarchy";
in
{
  # import sub modules
  imports =
    [
      ./core.nix
      ./ssh.nix
      ./shells
      ./spicetify.nix
    ]
    ++ lib.optionals (!isOmarchy) [
      # Omarchy seeds these as mutable files and owns their live theming.
      ./git.nix
      ./starship.nix
      ./terminals
    ]
    ++ lib.optionals isDarwin [
      # macOS-specific modules
      ./macos
    ]
    ++ lib.optionals isLinux [
      # Linux-specific modules
      ./linux
    ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home = {
    username = username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";

    # This value determines the Home Manager release that your configuration is compatible with.
    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # XDG directories
  xdg.enable = isLinux;
}
