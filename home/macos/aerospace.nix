{ pkgs, lib, ... }:

{
  # Move the aerospace config here since it's macOS-specific
  home.file.".aerospace.toml".source = ../aerospace/aerospace.toml;
}
