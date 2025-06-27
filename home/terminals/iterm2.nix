{ pkgs, lib, ... }:

{
  # iTerm2 configuration with official Shades of Purple theme
  # Creates the .itermcolors file for manual import
  
  home.file.".config/iterm2/shades-of-purple.itermcolors".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"\>
    <plist version="1.0">
    <dict>
        <key>Background Color</key>
        <dict>
            <key>Alpha Component</key>
            <real>1</real>
            <key>Blue Component</key>
            <real>0.25098040699958801</real>
            <key>Color Space</key>
            <string>sRGB</string>
            <key>Green Component</key>
            <real>0.11372549086809158</real>
            <key>Red Component</key>
            <real>0.11764705926179886</real>
        </dict>
        <key>Foreground Color</key>
        <dict>
            <key>Alpha Component</key>
            <real>1</real>
            <key>Blue Component</key>
            <real>1</real>
            <key>Color Space</key>
            <string>sRGB</string>
            <key>Green Component</key>
            <real>1</real>
            <key>Red Component</key>
            <real>0.99999600648880005</real>
        </dict>
        <key>Cursor Color</key>
        <dict>
            <key>Alpha Component</key>
            <real>1</real>
            <key>Blue Component</key>
            <real>0.0</real>
            <key>Color Space</key>
            <string>sRGB</string>
            <key>Green Component</key>
            <real>0.81568628549575806</real>
            <key>Red Component</key>
            <real>0.98039215803146362</real>
        </dict>
    </dict>
    </plist>
  '';
}
