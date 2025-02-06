{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.services.gnome.gcr-ssh-agent;
in
{
  meta = {
    maintainers = lib.teams.gnome.members;
  };

  options = {
    services.gnome.gcr-ssh-agent = {
      enable = lib.mkEnableOption "GCR ssh-agent";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.packages = [ pkgs.gcr_4 ];

    environment.extraInit = ''
      if [ -z "$SSH_AUTH_SOCK" -a -n "$XDG_RUNTIME_DIR" ]; then
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"
      fi
    '';
  };
}
