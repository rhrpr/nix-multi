{
  pkgs,
  ...
}:
{
  programs.starship = {
    enable = true;

    enableZshIntegration = true;

    settings = {
      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };
      time = {
        disabled = false;
        format = "at [$time]($style)";
        time_format = "%T";
      };
      aws = {
        symbol = "🅰 ";
      };
      azure = {
        symbol = "󰠅";
      };
      gcloud = {
        # do not show the account/project's info
        # to avoid the leak of sensitive information when sharing the terminal
        format = "on [$symbol$active(\($region\))]($style) ";
        symbol = "🅶 ";
      };
    };
  };
}
