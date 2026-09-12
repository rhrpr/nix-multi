{
  pkgs ? import <nixpkgs> { },
  treefmtWrapper,
}:

pkgs.mkShell {
  name = "python-development";

  packages = with pkgs; [
    python3
    python3Packages.pip
    python3Packages.virtualenv
    python3Packages.pylint
    python3Packages.black
    python3Packages.isort
    git

    # Add treefmt and formatters
    treefmtWrapper
    nixfmt
    shfmt
    prettier # For formatting markdown and other files
  ];

  shellHook = ''
    echo "Python development devshell activated!"
    echo "Python version: $(python --version)"
    echo "treefmt available for code formatting"

    # Create a virtual environment if it doesn't exist
    if [ ! -d .venv ]; then
      echo "Creating new virtual environment..."
      python -m venv .venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate
  '';
}
