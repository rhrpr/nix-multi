{
  pkgs ? import <nixpkgs> { },
  treefmtWrapper,
}:

pkgs.mkShell {
  name = "go-development";

  packages = with pkgs; [
    go
    gopls
    gotools
    golangci-lint
    delve
    git

    # Add treefmt and formatters
    treefmtWrapper
    nixfmt
    shfmt
  ];

  shellHook = ''
    echo "Go development devshell activated!"
    echo "Go version: $(go version)"
    echo "gopls and golangci-lint available"

    # Set GOPATH if not already set
    export GOPATH="''${GOPATH:-$HOME/go}"
    export PATH="$GOPATH/bin:$PATH"
  '';
}
