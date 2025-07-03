# Darwin (macOS) secret management using agenix
{
  config,
  lib,
  pkgs,
  username,
  agenix,
  ...
}:

{
  imports = [
    agenix.darwinModules.default
  ];

  # Install agenix CLI tool
  environment.systemPackages = [
    agenix.packages.${pkgs.system}.default
  ];

  # Age configuration for Darwin
  age = {
    # Only configure secrets that are actually needed and have valid identity paths
    secrets = lib.mkIf (builtins.pathExists "/Users/${username}/.ssh/id_ed25519") {
      # Linux builder SSH key (only if we have the identity key)
      linux-builder-key = {
        file = ../../secrets/ssh-keys/linux-builder-key.age;
        mode = "0600";
        owner = "root";
        group = "wheel";
        path = "/etc/ssh/linux-builder_ed25519";
      };
    };

    # Age identity paths for decryption
    identityPaths = [
      "/Users/${username}/.ssh/id_ed25519"
    ];
  };

  # Create SSH configuration for Linux builder
  environment.etc."ssh/ssh_config.d/90-linux-builder.conf" = {
    text = ''
      Host linux-builder
        HostName linux-builder
        User builder
        Port 22
        IdentityFile /etc/ssh/linux-builder_ed25519
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
        LogLevel ERROR
    '';
  };

  # SSH agent configuration for user
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
