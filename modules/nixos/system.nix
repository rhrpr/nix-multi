{ config, pkgs, ... }:

###################################################################################
#
#  NixOS Linux System configuration with KDE Plasma desktop
#
###################################################################################
{
  system.stateVersion = "24.11"; # Use appropriate NixOS version

  # Networking
  networking.hostName = "nixos"; # Define your hostname
  networking.networkmanager.enable = true;
  
  # Locale settings
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_GB.UTF-8";
    LC_IDENTIFICATION = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_GB.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Time zone
  time.timeZone = "Europe/London";

  # Desktop environment
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
    desktopManager.plasma6.enable = true; # Using Plasma 6 as specified in configuration.nix
    
    # NVIDIA configuration
    videoDrivers = ["nvidia"];
    
    # Keyboard settings
    xkb = {
      layout = "us";
      variant = "";
      options = "caps:escape"; # Remap caps lock to escape for vim users
    };
  };

  # NVIDIA hardware configuration
  hardware = {
    graphics.enable = true;
    nvidia.modesetting.enable = true;
    nvidia.powerManagement.enable = false;
    nvidia.open = true; 
    nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Power management
  services.power-profiles-daemon.enable = true;
  powerManagement.enable = true;

  # Sound
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # Printing support
  services.printing.enable = true;

  # Configure default shell
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  environment.shells = [ pkgs.zsh ];

  # System-wide KDE Plasma settings
  programs.kdeconnect.enable = true;

  # KDE Plasma specific configurations
  programs.plasma = {
    enable = true;
    # Configure appearance
    configureKDE = true;
    colorScheme = "BreezeDark";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    nano
    nixfmt-rfc-style
  #   (vscode-with-extensions.override {
  #     vscodeExtensions = with vscode-extensions; [
  #       bbenoist.nix
  #       davidanson.vscode-markdownlint
  #       ms-python.vscode-pylance
  #       github.copilot
  #       github.copilot-chat
  #       ms-python.debugpy
  #       ms-python.python
  #       ms-python.vscode-pylance
  #       ms-vscode-remote.remote-ssh
  #       ms-vscode-remote.remote-ssh-edit
  #       mechatroner.rainbow-csv
  #       dbaeumer.vscode-eslint
  #       github.vscode-github-actions
  #       ms-azuretools.vscode-docker
  #     ];
  #   })
  ];

  # Configure global KDE settings
  environment.etc = {
    "xdg/kdeglobals".text = ''
      [KDE]
      SingleClick=false
      
      [General]
      ColorScheme=BreezeDark
      
      [Icons]
      Theme=breeze-dark
      
      [KFileDialog Settings]
      ShowHidden=true
      
      [PreviewSettings]
      MaximumSize=16777216
    '';
    
    "xdg/kwinrc".text = ''
      [Windows]
      BorderlessMaximizedWindows=true
      
      [Compositing]
      OpenGLIsUnsafe=false
      
      [Effect-DesktopGrid]
      BorderActivate=9
      
      [Effect-PresentWindows]
      BorderActivatePresentWindows=7
      BorderActivateAll=5
      
      [Effect-Cube]
      BorderActivate=7
      
      [Plugins]
      blurEnabled=true
      kwin4_effect_fadeEnabled=true
      kwin4_effect_fadedesktopEnabled=true
    '';
    
    "xdg/dolphinrc".text = ''
      [General]
      ShowFullPath=true
      ShowSelectionToggle=true
      
      [PreviewSettings]
      Plugins=appimagethumbnail,audiothumbnail,comicbookthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,mobithumbnail,opendocumentthumbnail,svgthumbnail,textthumbnail
    '';
  };

  # Configure auto-mounting of drives
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.devmon.enable = true;

  # Automatic screen locking
  services.xserver.displayManager.autoLogin.enable = false;
  services.screenlocker = {
    enable = true;
    lockCmd = "${pkgs.kscreenlocker}/bin/kscreenlocker --forcelock";
    inactiveInterval = 10; # Lock after 10 minutes of inactivity
  };

  # Font configuration
  fonts = {
    packages = with pkgs; [
      # icon fonts
      material-design-icons
      font-awesome
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.iosevka
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "DejaVu Serif" ];
        sansSerif = [ "DejaVu Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };
      enable = true;
    };
    fontDir.enable = true;
  };

  # Enable automatic system upgrades
  system.autoUpgrade = {
    enable = false;
    allowReboot = false;
  };

  # Set default applications
  xdg.mime.defaultApplications = {
    "text/plain" = "org.kde.kate.desktop";
    "application/pdf" = "org.kde.okular.desktop";
    "image/png" = "org.kde.gwenview.desktop";
    "image/jpeg" = "org.kde.gwenview.desktop";
  };

  # User authentication with fingerprint reader (if available)
  services.fprintd.enable = true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
}
