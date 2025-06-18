# Agenix secrets configuration
let
  # User SSH keys (actual keys from system)
  hrpr-macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOccWnhsDCvcVtJCW9jIN40YOYmhvplINkykAOzANXSO hrpr@macbook-pro";
  
  # System keys (will be populated after system setup)
  # macbook-host = "ssh-ed25519 AAAAC3..."; # Add system host key after setup
  
  # All keys that can decrypt secrets
  allKeys = [ hrpr-macbook ]; # Add macbook-host after getting system key
  
in
{
  # SSH Keys for services and systems
  "ssh-keys/id_ed25519.age".publicKeys = allKeys;
  "ssh-keys/id_ed25519_pub.age".publicKeys = allKeys;
  
  # Linux builder SSH keys (for nix-darwin cross-compilation)
  "ssh-keys/linux-builder-key.age".publicKeys = allKeys;
  "ssh-keys/linux-builder-host-key.age".publicKeys = allKeys;
  
  # Service-specific SSH keys
  "ssh-keys/github-deploy-key.age".publicKeys = allKeys;
  "ssh-keys/server-access-key.age".publicKeys = allKeys;
  
  # Legacy secrets (keep for compatibility)
  "linux-builder-ssh-key.age".publicKeys = allKeys;
  "linux-builder-host-key.age".publicKeys = allKeys;
  "example-secret.age".publicKeys = allKeys;
}