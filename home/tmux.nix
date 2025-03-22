{ config, lib, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    clock24 = true;
    escapeTime = 0;
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    historyLimit = 10000;
    
    extraConfig = ''
      # Improve colors
      set -g default-terminal "screen-256color"
      
      # Set prefix to Ctrl+a
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix
      
      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
      
      # Split panes
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      
      # Navigate panes
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      
      # Resize panes
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      
      # Status bar
      set -g status-style bg=default,fg=white
      set -g window-status-current-style fg=green,bold
      set -g status-interval 60
      set -g status-left-length 30
      set -g status-left '#[fg=green](#S) '
      set -g status-right '#[fg=yellow]%H:%M #[fg=white]%d-%b-%y'
    '';
    
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };
}