{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.gregnix.programs.terminal.tools.fzf;
in
{
  options.gregnix.programs.terminal.tools.fzf = {
    enable = lib.mkEnableOption "fzf";
  };

  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;

      defaultCommand = "${lib.getExe pkgs.fd} --type=f --hidden --exclude=.git";
      defaultOptions = [
        "--layout=reverse" # Top-first.
        "--exact" # Substring matching by default, `'`-quote for subsequence matching.
        "--bind=alt-p:toggle-preview,alt-a:select-all"
        "--multi"
        "--no-mouse"
        "--info=inline"

        # Style and widget layout
        "--ansi"
        "--with-nth=1.."
        "--pointer=' '"
        "--header-first"
        "--border=rounded"
      ];

      # Atuin takes over Ctrl-R history search when enabled.
      historyWidget.command = lib.mkIf config.programs.atuin.enable "";

      enableBashIntegration = true;
      enableZshIntegration = true;
      enableFishIntegration = true;

      tmux.enableShellIntegration = true;
    };
  };
}
