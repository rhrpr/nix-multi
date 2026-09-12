{
  pkgs,
  lib,
  ...
}:
{
  # XDG mime associations for web browsing
  xdg.mimeApps =
    let
      browserDesktop = "firefox.desktop";
      webAssociations = [
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-html"
        "application/x-extension-xht"
        "application/x-extension-htm"
        "x-scheme-handler/unknown"
        "x-scheme-handler/mailto"
        "x-scheme-handler/chrome"
        "x-scheme-handler/about"
        "x-scheme-handler/https"
        "x-scheme-handler/http"
        "application/xhtml+xml"
        "application/json"
        "text/html"
      ];
      associations = builtins.listToAttrs (
        map (name: {
          inherit name;
          value = browserDesktop;
        }) webAssociations
      );
    in
    {
      associations.added = associations;
      defaultApplications = associations;
    };

  # Firefox configuration (for shared policies)
  programs.firefox = {
    enable = true;
    policies =
      let
        locked = value: {
          Value = value;
          Status = "locked";
        };
      in
      {
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
        Preferences = builtins.mapAttrs (_: locked) {
          "browser.tabs.warnOnClose" = false;
          "media.videocontrols.picture-in-picture.video-toggle.enabled" = true;
        };
      };
  };

  programs.librewolf = {
    enable = true;
    settings = {
      "beacon.enabled" = false;
      "browser.startup.page" = 3;
      "device.sensors.enabled" = false;
      "dom.battery.enabled" = false;
      "dom.event.clipboardevents.enabled" = false;
      "geo.enabled" = false;
      "media.peerconnection.enabled" = false;
      "privacy.clearHistory.cookiesAndStorage" = false;
      "privacy.clearHistory.siteSettings" = false;
      "privacy.firstparty.isolate" = true;
      "privacy.resistFingerprinting" = false;
      "privacy.trackingprotection.enabled" = true;
      "privacy.trackingprotection.socialtracking.enabled" = true;
      "webgl.disabled" = true; # may be annoying
    };
  };
}
