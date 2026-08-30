# Darwin (macOS) secret management using agenix
{
  config,
  lib,
  pkgs,
  username,
  agenix,
  ...
}:

let
  homeDir = "/Users/${username}";
  sshDir = "${homeDir}/.ssh";
  # Guard: only activate secrets if the agenix identity key is already in place.
  # On a fresh install, copy ~/.ssh/agenix-macos manually before rebuilding.
  hasIdentity = builtins.pathExists "${sshDir}/agenix-macos";
in
{
  imports = [
    agenix.darwinModules.default
  ];

  environment.systemPackages = [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  age = {
    secrets = lib.mkIf hasIdentity {
      ssh-id-ed25519 = {
        file = ../../secrets/ssh-keys/id_ed25519.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/id_ed25519";
      };
      ssh-id-rsa = {
        file = ../../secrets/ssh-keys/id_rsa.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/id_rsa";
      };
      ssh-github = {
        file = ../../secrets/ssh-keys/github.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/github.com";
      };
      ssh-proxmox = {
        file = ../../secrets/ssh-keys/proxmox.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/proxmox";
      };
      ssh-proxmox-nodes = {
        file = ../../secrets/ssh-keys/proxmox-nodes.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/proxmox-nodes";
      };
      ssh-raspberry-pi = {
        file = ../../secrets/ssh-keys/raspberry_pi.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/raspberry_pi";
      };
      # Backup copy of the NixOS agenix identity key
      ssh-agenix-nixos = {
        file = ../../secrets/ssh-keys/agenix-nixos.age;
        mode = "0600";
        owner = username;
        path = "${sshDir}/agenix-nixos";
      };
    };

    identityPaths = [
      "${sshDir}/agenix-macos"
    ];
  };

  # Ensure ~/.ssh exists with correct permissions before agenix activation
  system.activationScripts.sshDirSetup.text = ''
    install -d -m 700 -o ${username} ${sshDir}
  '';

  # SSH agent
  launchd.user.agents.ssh-agent = {
    serviceConfig = {
      Label = "ssh-agent";
      Program = "${pkgs.openssh}/bin/ssh-agent";
      ProgramArguments = [
        "${pkgs.openssh}/bin/ssh-agent"
        "-D"
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
