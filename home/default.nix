{ 
  username, 
  pkgs, 
  lib,
  desktopManager ? "plasma",
  isDarwin ? false,
  isLinux ? false,
  ... 
}:

{
  # import sub modules
  imports = [
    ./core.nix
    ./git.nix
    ./starship.nix
    ./shells
    ./terminals
  ] ++ lib.optionals isDarwin [
    # macOS-specific modules
    ./macos
  ] ++ lib.optionals isLinux [
    # Linux-specific modules
    ./linux
  ];

  # Home Manager needs a bit of information about you and the paths it should manage.
  home = {
    username = username;
    homeDirectory = if isDarwin 
      then "/Users/${username}" 
      else "/home/${username}";

    # This value determines the Home Manager release that your configuration is compatible with.
    stateVersion = "24.11";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # XDG directories
  xdg.enable = isLinux;
}
