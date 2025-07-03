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
  # SSH Keys that actually exist
  "ssh-keys/id_ed25519.age".publicKeys = allKeys;
  "ssh-keys/linux-builder-key.age".publicKeys = allKeys;
  "ssh-keys/github-deploy-key.age".publicKeys = allKeys;
}
