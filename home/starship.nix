{
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    settings = {
      add_newline = false;
      character = {
        success_symbol = "[➜](bold purple)";
        error_symbol = "[➜](bold red)";
      };
      directory = {
        style = "bold purple";
      };
      git_branch = {
        style = "bold purple";
        symbol = " ";
      };
      git_status = {
        style = "bold red";
        conflicted = "✘";
        ahead = "⇡";
        behind = "⇣";
        untracked = "★";
        stashed = "⚑";
        modified = "●";
        staged = "+";
        renamed = "»";
        deleted = "✖";
      };
      time = {
        disabled = false;
        format = "at [$time]($style)";
        time_format = "%T";
        style = "bold yellow";
      };
    };
  };
}