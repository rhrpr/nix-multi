{ config, lib, pkgs, ... }:

{
  home.file.".config/ghostty/config".text = ''
    # This is the configuration file for Ghostty.
    # The default template is here
    #   /Users/hrpr/Library/Application Support/com.mitchellh.ghostty/config
    #
    # Run `ghostty +show-config --default --docs` to view a list of
    # all available config options and their default values.
    # Additionally, each config option is also explained in detail
    # on Ghostty's website, at https://ghostty.org/docs/config.

    # Shades of Purple theme configuration
    # Background and foreground
    background = 1a1a22
    foreground = f8f8f2

    # Cursor
    cursor-color = ffd700
    cursor-text = 1a1a22

    # Selection
    selection-background = 44475a
    selection-foreground = f8f8f2

    # ANSI colors (0-15)
    palette = 0=#212134
    palette = 1=#ee5a52
    palette = 2=#7ac142
    palette = 3=#ffd700
    palette = 4=#82aaff
    palette = 5=#c792ea
    palette = 6=#21c7a8
    palette = 7=#f8f8f2
    palette = 8=#424450
    palette = 9=#ee5a52
    palette = 10=#7ac142
    palette = 11=#ffd700
    palette = 12=#82aaff
    palette = 13=#c792ea
    palette = 14=#21c7a8
    palette = 15=#ffffff

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