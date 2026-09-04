{
  username,
  hostname,
  ...
}@args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = hostname;
  networking.computerName = hostname;
  # Do not manage system.defaults.smb.NetBIOSName here. Current macOS creates
  # com.apple.smb.server.plist with a protected MACL on the first write, which
  # makes every later nix-darwin activation fail. computerName supplies the
  # same discoverable host identity without the non-idempotent defaults write.

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."${username}" = {
    home = "/Users/${username}";
    description = username;
  };

  users.groups.docker.members = [ username ];

  # Set the primary user for user-specific configurations
  system.primaryUser = username;

  nix.settings.trusted-users = [ username ];
}
