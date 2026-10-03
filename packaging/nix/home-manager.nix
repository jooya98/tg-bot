self:
{ config, lib, pkgs, ... }:

let
  cfg = config.services.tgBot;
  inherit (lib) mkEnableOption mkOption mkIf types;
  state = "%S/tgBot";
in
{
  options.services.tgBot = {
    enable = mkEnableOption "tgBot, a adaptive Telegram crawler/downloader";

    package = mkOption {
      type = types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = "tgBot flake package";
    };

    environmentFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/home/me/.config/tgBot.env";
      description = ''
        File with BOT_TOKEN (and optionally ALLOWED_USERS, API_SERVER_URL, …),
        kept out of the Nix store. Pass it as a string, not a Nix path literal.
      '';
    };

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        API_SERVER_URL = "http://localhost:8082";
        COOKIES_FILE = "/home/me/cookies/cookies.txt";
      };
      description = "Extra environment variables (see .env.example).";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.tgBot = {
      Unit = {
        Description = "tgBot — Telegram media downloader";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        RestartSec = 5;
        # ~/.local/state/tgBot — allowlist, media cache, log, …
        StateDirectory = "tgBot";
        Environment = lib.mapAttrsToList (k: v: "${k}=${v}") (
          {
            LOG_FILE = "${state}/tgBot.log";
            ALLOWED_CHATS_FILE = "${state}/allowed_chats.json";
            MEDIA_CACHE_FILE = "${state}/media_cache.json";
            MINIMAL_MODE_FILE = "${state}/minimal_mode.json";
            TOPIC_LOCK_FILE = "${state}/topic_locks.json";
          }
          // cfg.settings
        );
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
