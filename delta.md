# nix-darwin vs nixos-desktop: Configuration Delta

Comparison between `darwinConfigurations."Ryans-MacBook-Pro"` (`machines/macbook-pro.nix`)
and `nixosConfigurations."nixos-desktop"` (`machines/nixos-desktop.nix`).

---

## Module Composition

| Concern | macOS (nix-darwin) | NixOS Desktop |
|---|---|---|
| Hardware | — (not applicable) | `modules/nixos/hardware-configuration.nix` |
| Nix core | `modules/darwin/nix-core.nix` | `modules/nixos/nix-core.nix` |
| System | `modules/darwin/system.nix` | `modules/nixos/system.nix` |
| Users | `modules/darwin/host-users.nix` | `modules/nixos/host-users.nix` |
| Apps | `modules/darwin/apps.nix` | `modules/nixos/apps.nix` |
| AI tools | `modules/darwin/ai-tools.nix` | `modules/nixos/ai-tools.nix` **(file missing — see bug below)** |
| Desktop | — (not applicable) | `modules/nixos/desktop.nix` |
| Secrets | `modules/darwin/secrets.nix` | `modules/nixos/secrets.nix` |
| GPU | — | `modules/hosts/linux/gpu-passthrough.nix` |
| VM mgmt | `modules/hosts/macos/vm-management.nix` | `modules/hosts/linux/vm-management.nix` |
| Linux builder | `modules/hosts/macos/linux-builder.nix` | — |
| VM tools (shared) | `modules/shared/vm-tools.nix` | `modules/shared/vm-tools.nix` |
| HM modules | `spicetify` only | `plasma-manager` + `spicetify` |
| System module | `nix-openclaw.darwinModules.openclaw` | — |
| User file | `users/hrpr/darwin.nix` | `users/hrpr/nixos.nix` |

---

## Known Bug

~~`machines/nixos-desktop.nix` imports `../modules/nixos/ai-tools.nix` but that file does not exist
in the repository.~~ **Fixed** — `modules/nixos/ai-tools.nix` has been created, mirroring the
darwin equivalent with the full llm-agents overlay package set. One difference: openclaw has no
NixOS system service module (darwin gets `nix-openclaw.darwinModules.openclaw` loaded in
`lib/mksystem.nix`); the binary is installed but runs manually on NixOS.

---

## nix-core

| Setting | macOS | NixOS |
|---|---|---|
| `nix.enable` | (default) | `false` (NixOS manages the daemon) |
| `experimental-features` | `["nix-command" "flakes"]` (combined) | split: `flakes` + `extra-experimental-features = ["nix-command"]` |
| `connect-timeout` | `5` | not set |
| `stalled-download-timeout` | `300` | not set |
| `http-connections` | `25` | not set |
| `max-jobs` | `"auto"` | not set |
| `cores` | `0` (all) | not set |
| Store optimisation | `optimise.automatic = true` | `settings.auto-optimise-store = true` (older option) |
| Garbage collection | not configured | weekly, `--delete-older-than 7d` |

---

## system.nix

### macOS-only
- Detailed UI defaults: Dock (autohide, hot corners), Finder (hidden files, extensions, list view), Control Center (BT, Focus, Sound, Display, NowPlaying), Trackpad (tap-to-click, right-click, three-finger drag), Activity Monitor sort
- NSGlobalDomain: dark mode, key repeat (`InitialKeyRepeat=15`, `KeyRepeat=3`), disable autocorrect/autocapitalisation/smart quotes
- CustomUserPreferences: Finder desktop icons, `.DS_Store` suppression on network/USB, Spaces per-display, screensaver password, screenshot path/format, disable Apple personalised ads, disable Photos auto-open
- Login window: guest disabled, show full name
- Keyboard: CapsLock → Escape remap
- TouchID sudo (`security.pam.services.sudo_local.touchIdAuth = true`, `reattach = true` for tmux)
- `fonts.packages`: material-design-icons, font-awesome, nerd-fonts (fira-code, jetbrains-mono, iosevka)
- `environment.shells = [pkgs.zsh]`
- `system.stateVersion = 5`

### NixOS-only
- Boot: systemd-boot, EFI, `boot.initrd.systemd.enable`
- Secure Boot: activation script using `sbctl` (create-keys, enroll with Microsoft certs, sign EFI binaries on every switch)
- Kernel params: `nvidia-drm.modeset=1`, `NVreg_PreserveVideoMemoryAllocations`, `mem_sleep_default=deep`, `acpi_sleep=nonvs`, `acpi.ec_no_wakeup=1`
- NetworkManager enabled at system level
- Locale: `en_GB.UTF-8` with full `LC_*` overrides
- Programs: `firefox.enable`, `dconf.enable`
- Services: `pcscd.enable` (at system level, not apps.nix)
- Hardware: `enableRedistributableFirmware`, `linux-firmware` package, NVIDIA (modesetting, power management, GSP disabled, forceFullCompositionPipeline, open driver default)
- `services.xserver.videoDrivers = ["nvidia"]`
- SystemD sleep: `HibernateDelaySec=30min`, `SuspendState=mem`
- `system.stateVersion = "24.11"`

---

## apps.nix: Package Manager Strategy

macOS uses **Homebrew** as the primary package manager for GUI and CLI tools. Nix packages are
limited to a small set of core tools (`git`, `ripgrep`, `neovim`, `just`, `devbox`,
`nodejs_latest`, `nixfmt`, `treefmt`, `libfido2`).

NixOS uses **nix packages only** — no Homebrew equivalent.

### Packages present on macOS (Homebrew) but absent on NixOS

| Package | Type | Notes |
|---|---|---|
| Ableton Live Standard | cask | DAW |
| Arturia Software Center | cask | |
| Aural | cask | audio player |
| Battery | cask | macOS battery management |
| BetterDisplay | cask | HiDPI scaling |
| Brave Browser | cask | |
| Blender | cask | |
| ChatGPT | cask | |
| Codex | cask | |
| Cursor | cask | also in NixOS as `code-cursor` |
| Claude (.app) | cask | GUI app via brew; NixOS has claude-code CLI |
| Cyberduck | cask | |
| Docker Desktop | cask | |
| GIMP | cask | |
| GitHub Copilot for Xcode | cask (commented) | |
| iTerm2 | cask | |
| IntelliJ IDEA CE | cask | |
| JetBrains Air | cask | |
| LM Studio | cask | local AI runner |
| OBS | cask | |
| Proton Mail Bridge | cask | |
| ProtonVPN | cask | NixOS has `protonvpn-gui` |
| Rekordbox | cask | DJ software |
| Rectangle | cask | window snapping |
| Transmission | cask | NixOS has `transmission_4` |
| Yubico Authenticator | cask | NixOS has `yubioath-flutter` |
| iMovie | MAS | |
| Xcode | MAS | |
| Bitwarden | MAS | NixOS has `bitwarden-desktop` |
| azure-cli | brew | |
| age | brew | agenix CLI |
| cask | brew | Homebrew extension mechanism |
| fastlane | brew | also in NixOS |
| gallery-dl | brew | also in NixOS |
| jansson | brew | also in NixOS |
| lume | brew | UTM/VM CLI |
| mas | brew | Mac App Store CLI |
| regclient | brew | Docker registry sync |
| taglib | brew | |
| tfenv | brew | Terraform version manager |
| terraform-ls | brew | NixOS has it too |
| tree-sitter | brew | NixOS has it too |
| xcodegen | brew | |
| Taps | nikitabobko/tap, FelixKratz/formulae, trycua/lume, hashicorp/tap | |

### Packages present on NixOS but absent on macOS

| Package | Notes |
|---|---|
| `android-studio` | macOS has it as a commented-out cask |
| `gparted` | partition manager |
| `gnumake` | |
| `gmp` | |
| `pciutils` | `lspci` etc. |
| `whatsapp-for-linux` | |
| `steam` | macOS has commented-out cask |
| `transmission_4` | macOS has Transmission cask |
| `bitwarden-desktop` | macOS has Bitwarden via MAS |
| `yubioath-flutter` | macOS has Yubico Authenticator cask |
| `protonvpn-gui` | macOS has ProtonVPN cask |
| `code-cursor` | macOS has Cursor cask |

### programs.tmux
- macOS: not configured via nix (tmux is a brew formula)
- NixOS: `programs.tmux.enable = true`, `shortcut = "a"`, `terminal = "screen-256color"`

---

## AI Tools (modules/darwin/ai-tools.nix vs missing nixos equivalent)

macOS has a fully populated `ai-tools.nix` using the `llm-agents` overlay. NixOS references the
file but it does not exist.

macOS AI packages (via `llm-agents.packages`):

| Package | Category |
|---|---|
| `claude-code` | AI Coding Agent |
| `codex` | AI Coding Agent |
| `copilot-cli` | AI Coding Agent |
| `gemini-cli` | AI Coding Agent |
| `hermes-agent` | AI Assistant |
| `hermes-desktop` | AI Assistant |
| `hermes-hud` | AI Assistant |
| `openclaw` | AI Assistant |
| `herdr` | Workflow |
| `backlog-md` | Workflow |
| `beads` | Workflow |
| `vibe-kanban` | Workflow |
| `gitbutler` | Workflow |
| `openspec` | Workflow |
| `trellis` | Workflow |
| `agentsview` | Analytics |
| `codegraph` | Analytics |
| `context-hub` | Analytics |

Note: `claude-code` is also installed via `home/core.nix` (Home Manager) on both platforms.

---

## host-users.nix

| Setting | macOS | NixOS |
|---|---|---|
| `networking.hostName` | yes | yes |
| `networking.computerName` | yes | no |
| `system.defaults.smb.NetBIOSName` | yes | no |
| User home path | `/Users/${username}` | — (in nixos.nix) |
| Docker group | `users.groups.docker.members` | — (in nixos.nix via extraGroups) |
| `system.primaryUser` | yes | no |
| `nix.settings.trusted-users` | yes | yes |

---

## users/hrpr/darwin.nix vs nixos.nix

| Setting | macOS | NixOS |
|---|---|---|
| Account type | standard (no `isNormalUser`) | `isNormalUser = true` |
| Shell | `pkgs.zsh` | `lib.mkForce pkgs.zsh` |
| Groups | docker (in host-users.nix) | wheel, networkmanager, audio, video, libvirtd, docker |
| Password | none set | hashed (SHA-512, 500k rounds) |
| Sudo | `%admin ALL=(ALL) NOPASSWD: ALL` | `security.sudo.wheelNeedsPassword = false` |
| SSH daemon | — | `services.openssh.enable = true` |
| NetworkManager | — (macOS native) | `networking.networkmanager.enable = true` |
| Audio | — (CoreAudio native) | PipeWire (alsa, alsa.support32Bit, pulse) |
| Homebrew | `enable = true`, cleanup=zap | — |

Note: `users/hrpr/darwin.nix` sets `homebrew.onActivation.cleanup = "zap"` while
`modules/darwin/apps.nix` overrides this with `lib.mkForce "none"`. The apps.nix value wins,
meaning the darwin.nix homebrew block is partially redundant.

---

## secrets.nix

| Setting | macOS | NixOS |
|---|---|---|
| Module import | `agenix.darwinModules.default` | `agenix.nixosModules.default` |
| SSH dir | `/Users/${username}/.ssh` | `/home/${username}/.ssh` |
| Dir creation | `system.activationScripts` (install -d) | `systemd.tmpfiles.rules` |
| Secrets guard | `lib.mkIf hasIdentity` (fresh-install safe) | always active (no guard) |
| Secret group field | not set | `group = "users"` on all secrets |
| Cross-platform backup | stores `agenix-nixos` key | stores `agenix-macos` key |
| Identity path | `~/.ssh/agenix-macos` | `~/.ssh/agenix-nixos` |
| SSH host key | — | `/etc/ssh/ssh_host_ed25519_key` via `services.openssh` |
| SSH agent | `launchd.user.agents.ssh-agent` (macOS launchd) | `systemd.user.services.ssh-agent` |
| SSH agent type | foreground (`-D` flag) | forking (`Type = "forking"`) |

---

## desktop.nix (NixOS-only, no macOS equivalent)

macOS uses Aerospace (configured in `home/macos/aerospace.nix`) as a tiling WM. There is no
system-level desktop module for macOS — the display server is native macOS.

NixOS desktop.nix provides:
- KDE Plasma 6 (SDDM + Wayland) — default for nixos-desktop
- Hyprland support (used for VMs)
- PipeWire with Bluetooth audio (SBC-XQ, MSBC, HW volume)
- XDG portals (KDE portal for Plasma, Hyprland portal for Hyprland)
- Bluetooth (hardware + blueman service)
- Printing (CUPS + avahi mDNS)
- Steam + gamemode (x86_64 only)
- Fonts with fontconfig defaults (Noto Serif, Noto Sans, Fira Code, Noto Color Emoji)
- Additional KDE packages: kate, kdeconnect, okular, ark, dolphin, konsole, spectacle

---

## Home Manager

| Module | macOS | NixOS Desktop |
|---|---|---|
| Shared core | `home/core.nix` | `home/core.nix` |
| Git | `home/git.nix` | `home/git.nix` |
| SSH | `home/ssh.nix` | `home/ssh.nix` |
| Starship | `home/starship.nix` | `home/starship.nix` |
| Shells | `home/shells/` | `home/shells/` |
| Terminals | `home/terminals/` | `home/terminals/` |
| Spicetify | `home/spicetify.nix` | `home/spicetify.nix` |
| Platform home | `home/macos/` (vscode + aerospace) | `home/linux/` (vscode + browser + plasma) |
| XDG | disabled | enabled |
| Plasma Manager | not loaded | loaded as shared HM module |
| Extra packages | — | xclip, wl-clipboard, htop, btop, ranger, fd, bat |
| Browser config | — | `home/linux/browser.nix` |
| Plasma config | — | `home/linux/plasma.nix` |
| Aerospace config | `home/macos/aerospace.nix` | — |

---

## Summary: Parity Gaps

| Gap | Severity | Notes |
|---|---|---|
| ~~`modules/nixos/ai-tools.nix` missing~~ | ~~Critical~~ | **Fixed** — file created |
| openclaw no NixOS service module | Low | Binary installed; no systemd service wired up (darwin has launchd via nix-openclaw module) |
| Nix core settings inconsistent | Medium | macOS has `max-jobs`, `cores`, connection tuning; NixOS does not |
| GC only on NixOS | Low | macOS has no garbage collection configured |
| `auto-optimise-store` (NixOS) vs `optimise.automatic` (macOS) | Low | Different option paths; functionally equivalent but should be aligned |
| `users/hrpr/darwin.nix` homebrew block | Low | Partially overridden by `modules/darwin/apps.nix`; cleanup=zap is a no-op |
| secrets fresh-install guard | Medium | macOS has `hasIdentity` guard; NixOS always tries to activate secrets (will fail without identity key) |
| SSH agent daemon style | Low | launchd foreground (macOS) vs systemd forking (NixOS) — both work, inconsistent approach |
| `nixfmt` + `treefmt` in macOS nix packages | Low | These are build/format tools also available in devShells; on NixOS they are absent from system packages |
