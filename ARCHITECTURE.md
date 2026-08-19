# **Multi-Platform Nix Flake Architecture Guideline**

This document outlines a standardized architecture for a multi-platform Nix Flake, integrating NixOS, nix-darwin, and Home Manager with a primary focus on secure secrets management.

# **Secrets Management Strategy**

Secrets management must be categorized by the machine's role, the data's sensitivity, and its lifecycle. We use a tiered approach to balance security and usability.

## **Security Sources**

Wherever possible, prioritize hardware security over software-based management.

- **macOS**: Secure Enclave.  
- **PC/Linux**: TPM, Nitrokey.

## **Categorization & Handling**

### **1\. Privacy Secrets (Reconnaissance Deterrence)**

These secrets include personal data (e.g., email addresses) and infrastructure details (e.g., internal IPs, internal URLs). While they lack inherent security value (access credentials), they provide an attacker with a map of the environment.

- **Handling**: Encrypted in the flake via `sops`. Upon arrival at the machine, they are rendered into RAM-backed config files (e.g., via `sops.templates` in `sops-nix`).  
- **Threat Model**: Access to these files requires persistent disk read access while the machine is running, which implies a significantly compromised system state.

### **2\. Security Secrets (Access Credentials)**

These include private keys, passwords, and access tokens that grant direct system access. Their protection must minimize disk/RAM exposure.

- **Handling**: Avoid RAM-backed files where possible. Prefer process injection.

#### **Tools & Enforcement**

- **CLI tools**: 1Password (headless - with service account); if impossible, use runtime SOPS decryption with Nix managing the wrapper.
- **Daemons**: Linux - Use systemd-creds with LoadCredential.
- **Flatpak apps (Linux)**: Use oo7 (or desktop environment's secret service).


## **Implementation Guidelines**

- **Nix Store Leak Protection**: Never write secrets via standard `home.file` declarations. Always use `sops.templates` to render sensitive data to RAM-backed paths (e.g., `/run/user/1000/`) to prevent leaking plaintext into the world-readable Nix store.  
- **Lifecycle Management**: Use `systemd-tmpfiles` (Linux) and `launchd` agents (macOS) for dynamic cache cleanup of mutable tokens, ensuring no orphaned credentials persist on physical disk.

