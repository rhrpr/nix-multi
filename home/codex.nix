{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    (pkgs.stdenv.mkDerivation {
      name = "codex";
      src = pkgs.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        rev = "main"; # Replace with a specific commit hash for stability
      };
      buildInputs = [];
      installPhase = ''
        mkdir -p $out
        cp -r * $out
      '';
    })
  ];
}