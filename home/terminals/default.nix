{ pkgs, lib, ... }:

{
  imports = [
    ./ghostty.nix
    ./tmux.nix
  ];
}