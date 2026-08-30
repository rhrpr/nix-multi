# NixOS secret management using agenix
#
# Bootstrap: on first install, copy ~/.ssh/agenix-nixos to the machine manually
# before running nixos-rebuild, then subsequent rebuilds are fully automated.
# Optionally add the host's /etc/ssh/ssh_host_ed25519_key.pub to secrets.nix
# as a recipient for true zero-touch bootstrap.
{
  config,
  lib,
  pkgs,
  username,
  agenix,
  ...
}:

let
  homeDir = "/home/${username}";
  sshDir = "${homeDir}/.ssh";
in
{
  imports = [
    agenix.nixosModules.default
  ];

  environment.systemPackages = [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Ensure ~/.ssh exists before agenix activation
  systemd.tmpfiles.rules = [
    "d ${sshDir} 0700 ${username} users - -"
  ];

  age = {
    secrets = {
      ssh-id-ed25519 = {
        file = ../../secrets/ssh-keys/id_ed25519.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/id_ed25519";
      };
      ssh-id-rsa = {
        file = ../../secrets/ssh-keys/id_rsa.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/id_rsa";
      };
      ssh-github = {
        file = ../../secrets/ssh-keys/github.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/github.com";
      };
      ssh-proxmox = {
        file = ../../secrets/ssh-keys/proxmox.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/proxmox";
      };
      ssh-proxmox-nodes = {
        file = ../../secrets/ssh-keys/proxmox-nodes.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/proxmox-nodes";
      };
      ssh-raspberry-pi = {
        file = ../../secrets/ssh-keys/raspberry_pi.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/raspberry_pi";
      };
      # Backup copy of the macOS agenix identity key
      ssh-agenix-macos = {
        file = ../../secrets/ssh-keys/agenix-macos.age;
        mode = "0600";
        owner = username;
        group = "users";
        path = "${sshDir}/agenix-macos";
      };
    };

    identityPaths = [
      "${sshDir}/agenix-nixos"
    ];
  };

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

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
