{
  config,
  pkgs,
  lib,
  ...
}:

import ../vscode-shared.nix { inherit config pkgs lib; }
