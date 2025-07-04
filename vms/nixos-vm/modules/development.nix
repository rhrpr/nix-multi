{ config, pkgs, ... }:

{
  # Development tools
  environment.systemPackages = with pkgs; [
    # Editors
    vim
    neovim
    vscode

    # Version control
    git
    gh

    # Development tools
    nodejs
    python3
    go
    rustc
    cargo
    gnumake

    # System tools
    htop
    tree
    wget
    curl
    ripgrep
    fd

    # Containerization
    docker
    docker-compose
  ];

  # Programs
  programs = {
    zsh.enable = true;
    git.enable = true;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Development services
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
  };
}
