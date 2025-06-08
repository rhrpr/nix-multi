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
    theme = Dracula+
  '';
}