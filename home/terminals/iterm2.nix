{ pkgs, lib, ... }:

{
  # iTerm2 configuration with Shades of Purple theme
  # Since Home Manager doesn't have a built-in iTerm2 module,
  # we'll create the configuration file directly
  
  home.file."Library/Preferences/com.googlecode.iterm2.plist" = {
    text = ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Default Bookmark Guid</key>
        <string>shades-of-purple-profile</string>
        <key>New Bookmarks</key>
        <array>
          <dict>
            <key>Name</key>
            <string>Shades of Purple</string>
            <key>Guid</key>
            <string>shades-of-purple-profile</string>
            <key>Custom Directory</key>
            <string>Recycle</string>
            <key>Working Directory</key>
            <string>~/</string>
            
            <!-- Shades of Purple Color Scheme -->
            <key>Ansi 0 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.129411764705882</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.129411764705882</real>
              <key>Red Component</key>
              <real>0.129411764705882</real>
            </dict>
            
            <key>Ansi 1 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.372549019607843</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.372549019607843</real>
              <key>Red Component</key>
              <real>0.929411764705882</real>
            </dict>
            
            <key>Ansi 2 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.592156862745098</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.854901960784314</real>
              <key>Red Component</key>
              <real>0.509803921568627</real>
            </dict>
            
            <key>Ansi 3 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.345098039215686</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.827450980392157</real>
              <key>Red Component</key>
              <real>1</real>
            </dict>
            
            <key>Ansi 4 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>1</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.682352941176471</real>
              <key>Red Component</key>
              <real>0.505882352941176</real>
            </dict>
            
            <key>Ansi 5 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.949019607843137</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.576470588235294</real>
              <key>Red Component</key>
              <real>0.858823529411765</real>
            </dict>
            
            <key>Ansi 6 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>1</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.729411764705882</real>
              <key>Red Component</key>
              <real>0.313725490196078</real>
            </dict>
            
            <key>Ansi 7 Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.972549019607843</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.972549019607843</real>
              <key>Red Component</key>
              <real>0.972549019607843</real>
            </dict>
            
            <!-- Background and Foreground -->
            <key>Background Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.133333333333333</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.101960784313725</real>
              <key>Red Component</key>
              <real>0.101960784313725</real>
            </dict>
            
            <key>Foreground Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.972549019607843</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.972549019607843</real>
              <key>Red Component</key>
              <real>0.972549019607843</real>
            </dict>
            
            <!-- Cursor -->
            <key>Cursor Color</key>
            <dict>
              <key>Alpha Component</key>
              <real>1</real>
              <key>Blue Component</key>
              <real>0.345098039215686</real>
              <key>Color Space</key>
              <string>sRGB</string>
              <key>Green Component</key>
              <real>0.827450980392157</real>
              <key>Red Component</key>
              <real>1</real>
            </dict>
            
            <!-- Font Configuration -->
            <key>Normal Font</key>
            <string>FiraCode-Regular 14</string>
            <key>Use Non-ASCII Font</key>
            <false/>
            
            <!-- Terminal Settings -->
            <key>Terminal Type</key>
            <string>xterm-256color</string>
            <key>Scrollback Lines</key>
            <integer>10000</integer>
            <key>Silence Bell</key>
            <true/>
            <key>Use Bold Font</key>
            <true/>
            <key>Use Bright Bold</key>
            <true/>
            <key>Use Italic Font</key>
            <true/>
            
            <!-- Window Settings -->
            <key>Transparency</key>
            <real>0.05</real>
            <key>Blur</key>
            <true/>
            <key>Blur Radius</key>
            <real>2</real>
          </dict>
        </array>
      </dict>
      </plist>
    '';
  };
}