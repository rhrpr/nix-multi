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
  system.defaults.smb.NetBIOSName = hostname;

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
