{ pkgs, lib, ... }:

let
  loopbackScript = pkgs.writeShellScript "audio-loopback-daemon.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail
    SA_BIN="${pkgs.switchaudio-osx}/bin/SwitchAudioSource"
    TARGET_OUTPUT="Loopback Audio"
    POLL_INTERVAL=2
    log() { logger -t audio-loopback "$*"; }
    while true; do
      current="$("$SA_BIN" -t output -c 2>/dev/null)"
      if [[ "$current" != "$TARGET_OUTPUT" ]]; then
        log "輸出裝置 '$current' → 切換至 '$TARGET_OUTPUT'"
        "$SA_BIN" -t output -s "$TARGET_OUTPUT" || log "切換失敗"
      fi
      sleep "$POLL_INTERVAL"
    done
  '';
in
{
  environment.systemPackages = [ pkgs.switchaudio-osx ];

  launchd.user.agents.audioLoopback = {
    # 這裡改用 command，指向派生檔的可執行路徑
    command = "${loopbackScript}";

    serviceConfig = {
      KeepAlive       = true;
      RunAtLoad       = true;
      StandardOutPath = "/tmp/loopback.out.log";
      StandardErrorPath = "/tmp/loopback.err.log";
    };
  };
}