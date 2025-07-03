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

  nix.settings.trusted-users = [ username ];
}
