{
  username,
  hostname,
  ...
} @ args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = hostname;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users."${username}" = {
    home = "/home/${username}";
    description = username;
  };

  nix.settings.trusted-users = [username];
}
