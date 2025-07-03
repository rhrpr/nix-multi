{ pkgs, lib, ... }:

{
  imports = [
    ./vscode.nix
    ./aerospace.nix
  ];

  # macOS-specific packages
  home.packages =
    with pkgs;
    lib.optionals stdenv.isDarwin [
      # Add any macOS-specific packages here
    ];
}
