{ pkgs, ... }:

let
  # Enhanced VM creation script using UTM scripting best practices
  createVMScript = pkgs.writeShellScriptBin "create-nixos-vm" ''
    ${builtins.readFile ./utm-scripts/create-vm.sh}
  '';

  # Enhanced VM management with UTM CLI best practices
  manageVMScript = pkgs.writeShellScriptBin "manage-nixos-vm" ''
    ${builtins.readFile ./utm-scripts/manage-nixos-vm.sh}
  '';

in
{
  environment.systemPackages = with pkgs; [
    qemu
    createVMScript
    manageVMScript
    openssh
    rsync
  ];

  environment.shellAliases = {
    vm = "manage-nixos-vm";
    vm-create = "manage-nixos-vm create";
    vm-start = "manage-nixos-vm start";
    vm-stop = "manage-nixos-vm stop";
    vm-status = "manage-nixos-vm status";
    vm-ssh = "manage-nixos-vm ssh";
    vm-deploy = "manage-nixos-vm deploy";
    vm-ip = "manage-nixos-vm ip";
    vm-console = "manage-nixos-vm console";
    vm-list = "manage-nixos-vm list";
    vm-clone = "manage-nixos-vm clone";
    vm-delete = "manage-nixos-vm delete";
    vm-exec = "manage-nixos-vm exec";
  };
}
