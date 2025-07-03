# NixOS secret management module using agenix
{
  config,
  lib,
  pkgs,
  agenix,
  username,
  ...
}:

{
  imports = [
    agenix.nixosModules.default
  ];

  # Install agenix CLI tool
  environment.systemPackages = [
    agenix.packages.${pkgs.system}.default
  ];

  # Age configuration
  age = {
    # Secrets configuration - only reference existing secrets
    secrets = {
      # Main SSH private key for user
      ssh-private-key = {
        file = ../../secrets/ssh-keys/id_ed25519.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "/home/${username}/.ssh/id_ed25519_agenix";
      };

      # Linux builder SSH key
      linux-builder-key = {
        file = ../../secrets/ssh-keys/linux-builder-key.age;
        mode = "0600";
        owner = "root";
        group = "wheel";
        path = "/etc/ssh/linux-builder_ed25519";
      };

      # GitHub deploy key (example)
      github-deploy-key = {
        file = ../../secrets/ssh-keys/github-deploy-key.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "/home/${username}/.ssh/github_deploy_key";
      };
    };

    # Age keys (will be set per system)
    identityPaths = [
      "/etc/ssh/ssh_host_ed25519_key"
      "/home/${username}/.ssh/id_ed25519"
    ];
  };

  # Ensure SSH host keys exist for age decryption
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # SSH agent service for user
  systemd.user.services.ssh-agent = {
    description = "SSH Agent";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "forking";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.socket";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -a $SSH_AUTH_SOCK";
    };
  };
}
