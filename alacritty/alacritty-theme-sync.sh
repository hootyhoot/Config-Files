#!/bin/bash
# Keeps Alacritty's colors in sync with macOS light/dark mode by rewriting the
# "theme" block at the bottom of the Alacritty config (Alacritty live-reloads it),
# and tells a running Claude Code about the change so its "auto" theme follows.
#
# Started per shell from ~/.zshrc; it exits when that shell closes (e.g. Cmd+Q):
#   [[ -n $ALACRITTY_WINDOW_ID ]] && ("/path/to/alacritty-theme-sync.sh" watch $$ &) >/dev/null 2>&1
#
#   ./alacritty-theme-sync.sh             apply the current mode once

CONFIG="${ALACRITTY_CONFIG:-$HOME/.alacritty.toml}"
BEGIN="# >>> theme (managed by alacritty-theme-sync.sh) >>>"
END="# <<< theme <<<"

dark() {
  cat <<'EOF'
[colors.primary]
background = '#24292e'
foreground = '#d1d5da'

[colors.normal]
black   = '#586069'
red     = '#ea4a5a'
green   = '#34d058'
yellow  = '#ffea7f'
blue    = '#2188ff'
magenta = '#b392f0'
cyan    = '#39c5cf'
white   = '#d1d5da'

[colors.bright]
black   = '#959da5'
red     = '#f97583'
green   = '#85e89d'
yellow  = '#ffea7f'
blue    = '#79b8ff'
magenta = '#b392f0'
cyan    = '#56d4dd'
white   = '#fafbfc'
EOF
}

light() {
  cat <<'EOF'
[colors.primary]
background = '#ffffff'
foreground = '#24292f'

[colors.normal]
black   = '#24292e'
red     = '#d73a49'
green   = '#28a745'
yellow  = '#dbab09'
blue    = '#0366d6'
magenta = '#5a32a3'
cyan    = '#0598bc'
white   = '#6a737d'

[colors.bright]
black   = '#959da5'
red     = '#cb2431'
green   = '#22863a'
yellow  = '#b08800'
blue    = '#005cc5'
magenta = '#5a32a3'
cyan    = '#3192aa'
white   = '#d1d5da'
EOF
}

current_mode() {
  [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == "Dark" ]] && echo dark || echo light
}

# Replace the managed block (or append it if missing); only write when it changed.
# Every open tab runs a watcher, so the file is swapped in with an atomic rename:
# another watcher (or Alacritty) never sees it truncated or half-written.
apply_theme() {
  local target tmp
  target=$(readlink -f "$CONFIG") || return
  [[ -s "$target" ]] || return   # never rebuild the config from an empty read
  tmp=$(mktemp "$target.XXXXXX") || return
  BLOCK="$("$1")" awk -v b="$BEGIN" -v e="$END" '
    $0 == b { print; print ENVIRON["BLOCK"]; skip = 1; found = 1; next }
    $0 == e { skip = 0 }
    !skip   { print }
    END     { if (!found) { print ""; print b; print ENVIRON["BLOCK"]; print e } }
  ' "$target" > "$tmp"
  if cmp -s "$tmp" "$target"; then rm -f "$tmp"; else chmod 644 "$tmp"; mv -f "$tmp" "$target"; fi
}

# Send the terminal's "color scheme changed" report (ESC[?997;1n dark, 2 light) as
# input to this shell's terminal, but only when Claude Code (or ssh, for a remote
# Claude) is in the foreground. Claude re-reads the terminal's background color when
# it gets it. An ssh tab sitting at a remote prompt gets a few junk characters.
notify_claude() {
  local fg
  fg=$(ps -o tpgid= -p "$SHELL_PID" | tr -d ' ')
  case "$(ps -o comm= -p "$fg" 2>/dev/null)" in *claude|*ssh) ;; *) return 0 ;; esac
  python3 - "$1" <<'EOF'
import fcntl, os, signal, sys, termios
signal.signal(signal.SIGTTOU, signal.SIG_IGN)  # allowed to write from the background
fd = os.open("/dev/tty", os.O_RDWR)
for c in ("\x1b[?997;%sn" % ("1" if sys.argv[1] == "dark" else "2")).encode():
    fcntl.ioctl(fd, termios.TIOCSTI, bytes([c]))
EOF
}

# Prints a line the moment macOS switches appearance (event-driven, no polling).
# The mode itself is read with current_mode: this process caches stale defaults.
observe() {
  exec osascript -l JavaScript <<'EOF'
ObjC.import('Foundation');
ObjC.registerSubclass({
  name: 'ThemeObserver',
  methods: { 'changed:': { types: ['void', ['id']], implementation: function () {
    $.NSFileHandle.fileHandleWithStandardOutput.writeData($('changed\n').dataUsingEncoding($.NSUTF8StringEncoding));
  } } }
});
$.NSDistributedNotificationCenter.defaultCenter.addObserverSelectorNameObject(
  $.ThemeObserver.alloc.init, 'changed:', 'AppleInterfaceThemeChangedNotification', $());
$.NSRunLoop.currentRunLoop.run;
EOF
}

watch() {
  local last mode
  last=$(current_mode)
  apply_theme "$last"
  exec 3< <(observe)
  trap 'pkill -P $$' EXIT
  while kill -0 "$SHELL_PID" 2>/dev/null; do
    # macOS's bash 3.2 returns 1 for both a timeout and EOF, so check the observer
    if ! read -r -t 2 <&3; then
      pgrep -qP $$ osascript || break      # observer died; otherwise a timeout, re-check anyway
    fi
    mode=$(current_mode)
    [[ "$mode" == "$last" ]] && continue
    apply_theme "$mode"
    last="$mode"
    # Claude answers the signal by asking Alacritty for its background color, so send
    # it once Alacritty has reloaded the config, plus a late retry in case it was slow.
    (sleep 0.1; notify_claude "$mode"; sleep 0.4; notify_claude "$mode") &
  done
}

case "$1" in
  watch) SHELL_PID="${2:?usage: $0 watch <shell pid>}"; watch ;;
  *) apply_theme "$(current_mode)" ;;
esac
