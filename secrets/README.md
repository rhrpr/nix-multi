# Secret Management with Agenix

This directory holds all secrets for the nix-multi configuration, encrypted with [agenix](https://github.com/ryantm/agenix) (age encryption via SSH keys).

## How it works

Agenix encrypts each secret to one or more **recipient** SSH public keys. Any machine holding the corresponding private key can decrypt its secrets at activation time. Secrets are committed to git as `.age` files — they are safe to store in version control because they are encrypted.

The root `secrets.nix` file is the **access control list**: it maps each `.age` file to the public keys that can decrypt it.

At system activation, agenix decrypts each declared secret and places the plaintext at a configured path with the configured owner and permissions. The plaintext never touches disk in plain form between reboots — it lives under `/run/agenix/` (a tmpfs) and is symlinked to the declared path.

---

## Directory layout

```
secrets.nix                        # Root ACL: maps .age files to recipient public keys
secrets/
  ssh-keys/
    id_ed25519.age                 # Main user SSH private key
    id_rsa.age                     # Main user RSA private key
    github.age                     # GitHub SSH key
    proxmox.age                    # Proxmox host key
    proxmox-nodes.age              # Proxmox node key
    raspberry_pi.age               # Raspberry Pi key
    agenix-macos.age               # macOS agenix identity key (backup copy)
    agenix-nixos.age               # NixOS agenix identity key (backup copy)
```

---

## secrets.nix — the access control list

`secrets.nix` at the repo root declares which public keys can decrypt which secrets:

```nix
let
  agenix-macos = "ssh-ed25519 AAAA... hrpr@macbook-pro";
  agenix-nixos = "ssh-ed25519 AAAA... hrpr@nixos-desktop";
  allKeys = [ agenix-macos agenix-nixos ];
in
{
  "secrets/ssh-keys/id_ed25519.age".publicKeys = allKeys;
  # ... one entry per .age file
}
```

Every secret is encrypted to `allKeys` so either machine can decrypt any secret. If you add a new machine, add its public key here and re-encrypt all secrets.

---

## Identity keys (root of trust)

Each machine has a dedicated **agenix identity key** — a separate ed25519 SSH key pair used only for decryption:

| Machine | Private key location | Public key in secrets.nix |
|---------|---------------------|---------------------------|
| macOS   | `~/.ssh/agenix-macos` | `agenix-macos` variable |
| NixOS   | `~/.ssh/agenix-nixos` | `agenix-nixos` variable |

These are not the same as your regular user SSH keys. They exist solely so agenix has a stable, known key to decrypt secrets with.

The identity keys are themselves stored as secrets (`agenix-macos.age`, `agenix-nixos.age`) so each machine holds a backup copy of the other's key after first activation.

---

## Module configuration

### flake.nix

Agenix is declared as a flake input and passed through `specialArgs` to every module:

```nix
inputs = {
  agenix = {
    url = "github:ryantm/agenix";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.darwin.follows = "darwin";
  };
};
```

`lib/mksystem.nix` then passes `agenix` via `specialArgs` so any module can receive it as a function argument.

### modules/darwin/secrets.nix

- Imports `agenix.darwinModules.default`
- Checks for `~/.ssh/agenix-macos` at evaluation time (`builtins.pathExists`); secrets are only activated if the identity key is already in place
- Sets `age.identityPaths = [ "~/.ssh/agenix-macos" ]`
- Declares each secret with its destination path, owner, and `mode = "0600"`
- Creates `~/.ssh` with correct permissions via `system.activationScripts`

### modules/nixos/secrets.nix

- Imports `agenix.nixosModules.default`
- Sets `age.identityPaths = [ "~/.ssh/agenix-nixos" ]`
- Declares the same set of secrets targeting `/home/hrpr/.ssh/`
- Creates `~/.ssh` via `systemd.tmpfiles.rules`
- Enables openssh so `/etc/ssh/ssh_host_ed25519_key` exists (can also serve as an identity)

---

## Bootstrap procedure (first install on a new machine)

Because secrets can only be decrypted by a machine that already holds the identity key, the very first rebuild requires a manual step.

### macOS

1. Generate a new identity key pair (or copy an existing one):
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/agenix-macos -C "agenix-macos" -N ""
   ```
2. Add the public key to `secrets.nix` as a new recipient (or reuse the existing one if restoring).
3. Re-encrypt all secrets so the new key can decrypt them:
   ```bash
   nix run github:ryantm/agenix -- -r -i ~/.ssh/agenix-macos
   ```
4. Run `darwin-rebuild switch --flake .#Ryans-MacBook-Pro`. Agenix will decrypt and place all secrets.

### NixOS

Same process using `agenix-nixos`:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/agenix-nixos -C "agenix-nixos" -N ""
# add public key to secrets.nix, re-encrypt, then:
sudo nixos-rebuild switch --flake .#nixos-plasma
```

After the first successful activation, each machine's identity key is decrypted from the backup `.age` file and placed at `~/.ssh/agenix-{macos,nixos}` automatically on subsequent rebuilds.

---

## Adding a new secret

1. **Create the encrypted file:**
   ```bash
   nix run github:ryantm/agenix -- -e secrets/ssh-keys/my-new-key.age
   ```
   This opens `$EDITOR`. Paste the secret, save, and close. The file is encrypted to all keys currently listed in `secrets.nix` for that path — but you must add the entry first (step 2) or agenix won't know which keys to use.

   Correct order:
   ```bash
   # 1. Add the entry to secrets.nix first
   # 2. Then create/edit the secret
   nix run github:ryantm/agenix -- -e secrets/ssh-keys/my-new-key.age
   ```

2. **Declare it in secrets.nix:**
   ```nix
   "secrets/ssh-keys/my-new-key.age".publicKeys = allKeys;
   ```

3. **Declare it in the platform module** (`modules/darwin/secrets.nix` and/or `modules/nixos/secrets.nix`):
   ```nix
   age.secrets.my-new-key = {
     file = ../../secrets/ssh-keys/my-new-key.age;
     mode = "0600";
     owner = username;
     path = "${sshDir}/my-new-key";
   };
   ```

4. **Rebuild** to activate:
   ```bash
   darwin-rebuild switch --flake .#Ryans-MacBook-Pro   # macOS
   sudo nixos-rebuild switch --flake .#nixos-plasma     # NixOS
   ```

---

## Editing an existing secret

```bash
nix run github:ryantm/agenix -- -e secrets/ssh-keys/id_ed25519.age
```

You must have a private key that matches one of the recipients listed in `secrets.nix` for that file. Agenix will decrypt it, open `$EDITOR`, then re-encrypt on save.

## Viewing a secret (for debugging)

```bash
nix run github:ryantm/agenix -- -d secrets/ssh-keys/id_ed25519.age
```

---

## Adding a new machine

1. Generate an identity key on the new machine:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/agenix-<hostname> -C "agenix-<hostname>" -N ""
   cat ~/.ssh/agenix-<hostname>.pub
   ```

2. Add the public key to `secrets.nix`:
   ```nix
   agenix-newhost = "ssh-ed25519 AAAA... hrpr@newhost";
   allKeys = [ agenix-macos agenix-nixos agenix-newhost ];
   ```

3. Re-encrypt all existing secrets so the new machine can decrypt them:
   ```bash
   nix run github:ryantm/agenix -- -r
   ```

4. Create a platform secrets module for the new machine (model after `modules/darwin/secrets.nix` or `modules/nixos/secrets.nix`).

5. Copy the identity key to the new machine manually (once), then rebuild.
