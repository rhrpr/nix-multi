{ config, lib, pkgs, ... }:

{
  home.file.".config/ghostty/config".text = ''
    # This is the configuration file for Ghostty.
    # Shades of Purple (Super Dark) theme configuration
    # Colors extracted from the official iTerm2 theme

    # Background and foreground - Super Dark Purple
    background = 1e1d40
    foreground = ffffff

    # Cursor - Golden Yellow
    cursor-color = fad000
    cursor-text = ffffff

    # Selection - Purple selection
    selection-background = b362ff
    selection-foreground = c2c2c2

    # ANSI colors (0-15) - Official Shades of Purple palette converted from iTerm2 theme
    palette = 0=#000000
    palette = 1=#d90429
    palette = 2=#3ad900
    palette = 3=#ffe700
    palette = 4=#6943ff
    palette = 5=#ff2b70
    palette = 6=#00c5c7
    palette = 7=#c7c7c7
    palette = 8=#676767
    palette = 9=#f9291b
    palette = 10=#42d425
    palette = 11=#f1d000
    palette = 12=#6871ff
    palette = 13=#ff76ff
    palette = 14=#79e7fa
    palette = 15=#feffff

    # Font configuration
    font-family = "FiraCode Nerd Font"
    font-size = 14

    # Window settings
    window-decoration = true

    # Other settings
    scrollback-limit = 10000
    copy-on-select = true
    
    # Terminal settings
    term = xterm-256color
  '';
}