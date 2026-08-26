# SSH client configuration managed by Home Manager
# Private keys are placed at ~/.ssh/ by agenix during system activation
# Public keys are written here (they are not sensitive)
{
  isDarwin,
  username,
  ...
}:

{
  programs.ssh = {
    enable = true;

    addKeysToAgent = if isDarwin then "yes" else "no";
    extraConfig = if isDarwin then "UseKeychain yes" else "";

    matchBlocks = {
      "debbie" = {
        hostname = "192.168.1.3";
        user = "root";
        port = 22;
        identityFile = "~/.ssh/proxmox";
        identitiesOnly = true;
      };

      "servarr" = {
        hostname = "192.168.1.4";
        user = "servarr";
        port = 22;
        identityFile = "~/.ssh/proxmox-nodes";
        identitiesOnly = true;
      };

      "vault" = {
        hostname = "192.168.1.5";
        user = "vault";
        port = 22;
        identityFile = "~/.ssh/proxmox-nodes";
        identitiesOnly = true;
      };

      "immmich" = {
        hostname = "192.168.1.6";
        user = "immich";
        port = 22;
        identityFile = "~/.ssh/proxmox-nodes";
        identitiesOnly = true;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/github.com";
        identitiesOnly = true;
      };
    };
  };

  # Public keys — written by home-manager (not sensitive, no encryption needed)
  home.file = {
    ".ssh/id_ed25519.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOh9k+6KbSgMfcDZXrHRt9DgxQ96ZPTCdK6o12LLRwhU\n";
      mode = "0644";
    };
    ".ssh/id_rsa.pub" = {
      text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDAsDB3G4J4sap3F+eVO7OzMbPh+/zCX40yllDw30gpUPnMcF9aPjk44nt1VwnDlx16WTDb1qZzKDOQVy4IVWphu7CCx7rH5vKxpvr0zM+bMtw8FXY0YhceLFDeK8foapwLPoyFZqAkcDyQV/ma78Lm6Q+b87bNtBdSH6djLbX4p1w+RTJEBmJFBNHQUnmG3xn4NOWcIuPgG9URmGNYDG8JcLlOT4v27e1HoZNJOb319TFiG3Fb/iCB4rqvVMApQmrCE91TjbH+K6LG4GDHbfb6SevtBZWp+udGWuGJewkG16nVEP9qBdHAKptkZtRCKczxCC8YBh/edJfxbnapq0Z/ZtKqMvZGUMhNb+bzZXoN0lzNQ/iz+FlAOjXTDrJIhz58EffNuI41a3+GwBqz26GB6pJ5oliMIj+sz7ovpaeGWRyNCuwNhB9e4Rzf2ccl6/6YR2xURgVxT5Qx9q2MWNCv6Ul6TzlX9BWN+3QDr3UTnyHrFcUdPmmPO7MVH03WH1iglq+aqoHZ+l8g8fHGk1NFf1pY7GLTcJw6CFKhQb5Udr5k+m7ON8OKWaAG0bZVHTKMiC3hCZ1f1/a4mtdldw3DxvNl0yp3ohwvjs1P3iUKeu1tXmMW4dpEs65QPzX8edXkoKvT3VSqBOQBRYESvP4pkUFxfjQ9qHKHv6Q7Qyrkew== hrpr@hrprbox\n";
      mode = "0644";
    };
    ".ssh/github.com.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM52oveiWVG3nNvzVQrlw9+by3kFXLzx+xPCCCQWX9Bb hrpr@hrprjaro\n";
      mode = "0644";
    };
    ".ssh/proxmox.pub" = {
      text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcmatQVmvcixnNv+Io1K4N3Sq6fEvS/3b2j6uu6MlGmf7nRwE9p3bZStDhVhGL4Fdqh85Sl56lcroNjkCAdXZ1AWZTS/zz+0y5tSfaY29R3TT9djLhEuBjOFs22OC6VFHszaOaH0Tb5XQSvzGh1AE7MGShL+cskCDlz/LQh9ZpbY+K4eZ0VRT2bZIhVQa/ebolKCQ/f0/HyV0HHFTDMuTUhItYQrwtus5+HI3Z1goSqsYysTK1WGPpTcKafr579AZpqhDFUaLz/2zPBd0u2NXwkDEAGiuUGGNYwx1EP84cZiFY8CuumUJCgsY29ky7GLq9JrE3uJu5JTM1ms5OuGjs5F8xPb/xyirDGUPCx9pNiWpZ1teCJwAvqVrUYdYS2oPN8yhOA5oEULRZHzgyQnhr7ZkPC1fSI27XaQt5f4Ofe5EWPO3ep1YTsjVrR2xFoP2H0jKvYFv56tCAHM6O9VLtuTv3WGbB/UeUqvhr24I/3VZNYJYfUhIDpS+enV9ynel8FCGb1yaeGb7Yrnc9Ab/9PLUmSusKd4h8DSj2pRGVqAgNDe7uOblsJ16LYNfHQkA7rCrrUKfxvuWPZtYPRHT09yLpg5nwFKHE913rDsqzZxRbTTiRrmymVjK6dFu/jifhtJJ32J7ZcnQcthEfKUf5C4rDWOS3fNUF2NNLVgqsC2w==\n";
      mode = "0644";
    };
    ".ssh/proxmox-nodes.pub" = {
      text = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5oUXPHXOFRKWl1Br1fWi9Cu22Z2Mk40g0fdiZACOAACsQXPy3i2K1YEvN3siOujlVTresXgfKo1b956NGYcId7EyQHY/TjYyMNtU7TNg0hD7ZfsVvaygynjcz2NTHN0Gk/c/ChDQhKoZOClcNgPog49U20ij8p0zVj6jFV57dlxR7rTWxDceaIFvsTEyFLwJR1GxZjxYm8vUhinMSQJQ+Gz2XuqQn8N6CKtpwFOc2UDtAKoabB+LqqYU3my96FKn5DI7JJGWaUd2nNZTnBMIVgXuiwsEzTq7CI+z/kb8eMOyQAt+iYRYxtx3WQn7z4/5laZfKXrus7lC6DFhCJ0DLiiJBR2HmbIkmeCp3S40yFNKlDLeooHOrPlPJM6Dk91Baq3qLRYFYE2ivReNwjF656K+gog+N3tKun3vTuMxBcSHSp2VBHutfSRpE0CJ+5IcdcKc6SkJwqutoV6jsPFwVq2ud9ziS/s2jPQTtGshN7ZDwfzAD5QladAtv0Bl6R5iVa56y0NssGHV435Un3Qgr4LIYIkga5a35hbSGtinDR0liJNUHaysXsellPGyRcQUsqx13FVHnLyk5BJMfT8cdQ/p8VnBBkEkDS7CBziRhvdQRe/KgCIKlu7PVjY8SC4qhIoy268212x7HDannWI06qUkvEed8DAykTkG1x5tMyQ== hrpr@HRPRBOX\n";
      mode = "0644";
    };
    ".ssh/raspberry_pi.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6JxU7Oz/58minyfFf+IhMbe0HBrtiiRhHEfTa2Sf6i hrpr@macbook-pro\n";
      mode = "0644";
    };
    ".ssh/agenix-macos.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+MGNiJqFMytK5nBXoCTnuL9U0mFFzfFXQYUPIZGIIK hrpr@macbook-pro\n";
      mode = "0644";
    };
    ".ssh/agenix-nixos.pub" = {
      text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUVQqvfbSxCVTYZVeFiL12GxkDqiA5wUNjK/cfBJy0U hrpr@nixos-desktop\n";
      mode = "0644";
    };
  };
}
