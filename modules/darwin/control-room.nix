##############################################################################
#
#  AI Control Room — system side (macOS).
#
#  Installs the desktop apps the control room drives and makes macOS put
#  windows back after a reboot. The user-level wiring (Herdr layout, voice,
#  AeroSpace rules, login agent) is in home/macos/control-room.
#
#  One-time manual grants (macOS will prompt; TCC cannot be set from Nix):
#    System Settings → Privacy & Security → Accessibility: AeroSpace, Hammerspoon
#    System Settings → Privacy & Security → Microphone:    Hammerspoon
#
##############################################################################
_:

{
  homebrew = {
    # Taps nikitabobko/tap and FelixKratz/formulae are declared in apps.nix.
    casks = [
      "nikitabobko/tap/aerospace" # i3-style tiling; workspace 1AI = control room
      "hammerspoon" # global hotkeys + push-to-talk voice layer
    ];
    brews = [
      "FelixKratz/formulae/borders" # focused-window border (AeroSpace startup)
    ];
  };

  system.defaults = {
    # AeroSpace recommends this: Mission Control grouping fights tiling.
    dock.expose-group-apps = true;

    # Reopen apps and windows after restart, so the desktop half of the
    # control room comes back along with the Herdr half.
    NSGlobalDomain.NSWindowShouldDragOnGesture = true; # ctrl+cmd drag any window
    CustomUserPreferences = {
      "com.apple.loginwindow".TALLogoutSavesState = true;
      NSGlobalDomain.NSQuitAlwaysKeepsWindows = true;
      # Hammerspoon: load ~/.hammerspoon/init.lua, start at login, no dock icon.
      "org.hammerspoon.Hammerspoon" = {
        MJShowDockIconKey = false;
        MJShowMenuIconKey = true;
      };
    };
  };
}
