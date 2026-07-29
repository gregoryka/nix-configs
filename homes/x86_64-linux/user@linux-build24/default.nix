_: {
  gregnix = {
    archetypes.work.enable = true;

    user = {
      enable = true;
      name = "user";
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
        starship.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        zoxide.enable = true;
      };
    };

    services.sops.enable = true;

    system.xdg.enable = true;
  };

  home.stateVersion = "26.05";
}
