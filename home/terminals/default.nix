{ pkgs, lib, ... }:

{
  imports = [
    ./ghostty.nix
    ./iterm2.nix
    ./tmux.nix
  ];
}
