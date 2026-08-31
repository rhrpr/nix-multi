{
  pkgs ? import <nixpkgs> { },
  treefmtWrapper,
}:

pkgs.mkShell {
  name = "rust-development";

  packages = with pkgs; [
    # Rust toolchain
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy

    # Development tools
    pkg-config
    openssl
    git

    # Optional useful tools for Rust development
    cargo-watch
    cargo-edit
    cargo-audit
    cargo-outdated
    
    # Build dependencies (common for many Rust projects)
    gcc
    
    # Add treefmt and formatters
    treefmtWrapper
    nixfmt
    shfmt
    nodePackages.prettier # For formatting markdown and other files
  ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    # macOS specific dependencies
    pkgs.darwin.apple_sdk.frameworks.Security
    pkgs.darwin.apple_sdk.frameworks.CoreFoundation
    pkgs.darwin.apple_sdk.frameworks.SystemConfiguration
  ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    # Linux specific dependencies
    libudev-zero
  ];

  shellHook = ''
    echo "Rust development devshell activated!"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
    echo "treefmt available for code formatting"
    
    # Set environment variables for development
    export RUST_SRC_PATH="${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}"
    export PKG_CONFIG_PATH="${pkgs.openssl.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
    
    # Helpful aliases
    alias cb="cargo build"
    alias cr="cargo run"
    alias ct="cargo test"
    alias cc="cargo check"
    alias cf="cargo fmt"
    alias ccl="cargo clippy"
  '';
}