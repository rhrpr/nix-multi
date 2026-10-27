# AeroSpace tiling WM config. The static part lives in ../aerospace/aerospace.toml;
# app → workspace rules are generated from programs.controlRoom.apps.
{ config, lib, ... }:

let
  cr = config.programs.controlRoom;
  base = builtins.readFile ../aerospace/aerospace.toml;
in
{
  home.file.".aerospace.toml".text =
    builtins.replaceStrings [ "@EXEC_PATH@" ] [ cr.execPath ] base
    + cr.aerospaceWindowRules
    + ''

      # Everything else floats in 0Other until it is given a home.
      [[on-window-detected]]
      check-further-callbacks = true
      run = ['layout floating', 'move-node-to-workspace 0Other']
    '';
}
