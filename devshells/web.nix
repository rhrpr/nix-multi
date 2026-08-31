{
  pkgs ? import <nixpkgs> { },
  treefmtWrapper,
}:

pkgs.mkShell {
  name = "web-development";

  packages = with pkgs; [
    nodejs
    yarn
    git

    # Additional web development tools
    nodePackages.typescript
    nodePackages.prettier
    nodePackages.eslint

    # Add treefmt and formatters
    treefmtWrapper
    nixfmt
    shfmt
  ];

  shellHook = ''
    echo "Web development devshell activated!"
    echo "Node.js version: $(node --version)"
    echo "Yarn version: $(yarn --version)"
    echo "treefmt available for code formatting"
  '';
}
