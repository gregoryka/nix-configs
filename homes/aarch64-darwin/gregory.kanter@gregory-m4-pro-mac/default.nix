{
  config,
  lib,

  ...
}:
{
  gregnix = {
    archetypes.work.enable = true;
    archetypes.devVmClient = {
      enable = true;
      identityFile = "${config.home.homeDirectory}/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/PublicKeys/2a0de6597331ac28668b1280985bad10.pub";
      vms."dev-vm" = {
        host = config.sops.placeholder.dev_vm_ip;
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILDnMt0VZYFyjEgXGpErGwT0VSJ4wZ90tbmW9IVaUxKQ";
      };
    };

    user = {
      enable = true;
      name = "gregory.kanter";
    };

    programs.terminal = {
      shell.zsh.enable = true;
      tools = {
        atuin.enable = true;
        bat.enable = true;
        direnv.enable = true;
        eza.enable = true;
        fd.enable = true;
        fzf.enable = true;
        gh.enable = true;
        git.enable = true;
        lazygit.enable = true;
        nh.enable = true;
        ripgrep.enable = true;
        ssh.enable = true;
        starship.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zoxide.enable = true;
      };
    };

    services.sops.enable = true;

    system.xdg.enable = true;
  };

  sops.secrets.dev_vm_ip.sopsFile = lib.getFile "secrets/work/gregory-m4-pro-mac/ssh.yaml";

  home.stateVersion = "26.05";
}
