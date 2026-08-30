{ pkgs, lib, ... }:

{
  imports = [
    ./vscode.nix
    ./aerospace.nix
    ./hermes.nix
  ];

  # macOS-specific packages
  home.packages =
    with pkgs;
    lib.optionals stdenv.hostPlatform.isDarwin [
      # Add any macOS-specific packages here
    ];
}
