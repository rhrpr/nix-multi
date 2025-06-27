{ config, lib, pkgs, ... }:

{
  home.file.".config/ghostty/config".text = ''
    # This is the configuration file for Ghostty.
    # Shades of Purple (Super Dark) theme configuration
    # Colors extracted from the official iTerm2 theme

    # Background and foreground - Super Dark Purple
    background = 1e1d40  # RGB(30, 29, 64) - Super Dark Purple
    foreground = ffffff  # RGB(255, 255, 255) - Pure White

    # Cursor - Golden Yellow
    cursor-color = fad000  # RGB(250, 208, 0) - Golden Yellow
    cursor-text = ffffff   # White text on cursor

    # Selection - Purple selection
    selection-background = b362ff  # RGB(179, 98, 255) - Purple selection
    selection-foreground = c2c2c2  # Light gray text

    # ANSI colors (0-15) - Official Shades of Purple palette
    palette = 0=#000000   # Black
    palette = 1=#d90429   # Red - RGB(217, 4, 41)
    palette = 2=#3ad900   # Green - RGB(58, 217, 0) 
    palette = 3=#ffe700   # Yellow - RGB(255, 231, 0)
    palette = 4=#6943ff   # Blue - RGB(105, 67, 255)
    palette = 5=#ff2b70   # Magenta - RGB(255, 43, 112)
    palette = 6=#00c5c7   # Cyan - RGB(0, 197, 199)
    palette = 7=#c7c7c7   # White - RGB(199, 199, 199)
    palette = 8=#686868   # Bright Black - RGB(104, 104, 104)
    palette = 9=#f92672   # Bright Red - RGB(249, 38, 114)
    palette = 10=#43d426  # Bright Green - RGB(67, 212, 38)
    palette = 11=#f1d000  # Bright Yellow - RGB(241, 208, 0)
    palette = 12=#6871ff  # Bright Blue - RGB(104, 113, 255)
    palette = 13=#ff77ff  # Bright Magenta - RGB(255, 119, 255)
    palette = 14=#79e8fb  # Bright Cyan - RGB(121, 232, 251)
    palette = 15=#ffffff  # Bright White - RGB(255, 255, 255)

    # Font configuration
    font-family = "FiraCode Nerd Font"
    font-size = 14

    # Window settings
    window-decoration = true
    window-opacity = 0.95

    # Other settings
    scrollback-limit = 10000
    copy-on-select = true
    
    # Terminal settings
    term = xterm-256color
  '';
}
    window-opacity = 0.95

    # Other settings
    scrollback-limit = 10000
    copy-on-select = true
    
    # Terminal settings
    term = xterm-256color
  '';
}