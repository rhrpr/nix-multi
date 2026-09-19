# Maintainer-specific agenix recipients. Forks should replace this file.
let
  # Agenix identity keys (one per machine, used to decrypt secrets)
  agenix-macos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+MGNiJqFMytK5nBXoCTnuL9U0mFFzfFXQYUPIZGIIK hrpr@macbook-pro";
  agenix-nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMUVQqvfbSxCVTYZVeFiL12GxkDqiA5wUNjK/cfBJy0U hrpr@nixos-desktop";

  # All recipients — every secret is encrypted to both so either machine can decrypt
  allKeys = [
    agenix-macos
    agenix-nixos
  ];
in
{
  # Main user identity
  "secrets/ssh-keys/id_ed25519.age".publicKeys = allKeys;
  "secrets/ssh-keys/id_rsa.age".publicKeys = allKeys;

  # Service / host-specific identities
  "secrets/ssh-keys/github.age".publicKeys = allKeys;
  "secrets/ssh-keys/proxmox.age".publicKeys = allKeys;
  "secrets/ssh-keys/proxmox-nodes.age".publicKeys = allKeys;
  "secrets/ssh-keys/raspberry_pi.age".publicKeys = allKeys;

  # Agenix identity keys themselves (backup copies, for reference on the other machine)
  # NOTE: these are the ROOT OF TRUST — bootstrap by copying manually on first install
  "secrets/ssh-keys/agenix-macos.age".publicKeys = allKeys;
  "secrets/ssh-keys/agenix-nixos.age".publicKeys = allKeys;
}
