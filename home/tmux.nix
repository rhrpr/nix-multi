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

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];

    extraConfig = ''
      ### Primeagen Tmux 1012-Mode 🧠⚡

      # Set prefix to Ctrl+a
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Mouse + Vi + History
      set -g mouse on
      set -g mode-keys vi
      set -g history-limit 10000

      # Colors
      set -g default-terminal "screen-256color"
      set -as terminal-overrides ',xterm-256color:Tc'

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"

      # Pane splits (in current working dir)
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Pane navigation (Prime-style)
      bind -n C-h select-pane -L
      bind -n C-j select-pane -D
      bind -n C-k select-pane -U
      bind -n C-l select-pane -R

      # Resize panes fast
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Tmux resurrection + continuum
      set -g @resurrect-dir '~/.tmux/resurrect'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '15'

      # Status bar (simple but functional)
      set -g status-style bg=default,fg=white
      set -g window-status-current-style fg=green,bold
      set -g status-interval 60
      set -g status-left-length 30
      set -g status-left '#[fg=green](#S) '
      set -g status-right '#[fg=yellow]%H:%M #[fg=white]%d-%b-%y'
    '';
  };
}
