# Test configuration file
{ config, pkgs, lib, ... }:

{
  # Minimal test configuration
  system.stateVersion = "24.11";
  
  # Test that arguments are passed correctly
  environment.systemPackages = [ pkgs.hello ];
}