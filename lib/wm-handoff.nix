{
  lib,
  pkgs,
  user,
}:
let
  asUser = lib.liberion.darwin.asUser user;
  stampDir = "/var/lib/wm-handoff";
in
{
  unparkYashiki = pkgs.writeShellApplication {
    name = "unpark-yashiki";
    runtimeInputs = [
      pkgs.yashiki
      pkgs.gnugrep
    ];
    text = ''
      yashiki list-outputs | grep -oE '^[0-9]+' | while read -r id; do
        yashiki tag-view --output "$id" 1023
      done
    '';
  };

  stop =
    {
      label,
      evacuate,
      leftovers ? [ ],
    }:
    ''
      uid="$(id -u ${user})"
      if ${asUser} launchctl print "gui/$uid/${label}" >/dev/null 2>&1; then
        timeout 30 sudo --user=${user} -- ${evacuate} ||
          echo "wm-handoff: could not evacuate windows from ${label}" >&2
        ${asUser} launchctl bootout "gui/$uid/${label}" || :
        for _ in $(seq 100); do
          ${asUser} launchctl print "gui/$uid/${label}" >/dev/null 2>&1 || break
          sleep 0.1
        done
        if ${asUser} launchctl print "gui/$uid/${label}" >/dev/null 2>&1; then
          echo "wm-handoff: ${label} did not stop within 10s" >&2
        fi
      fi
      ${lib.optionalString (
        leftovers != [ ]
      ) "rm -f ${lib.escapeShellArgs leftovers}"}
    '';

  reloadOnChange =
    {
      label,
      init,
      unpark,
    }:
    ''
      uid="$(id -u ${user})"
      new="$(readlink -f ${lib.escapeShellArg init} || :)"
      stamp=${stampDir}/${label}.init
      if [ -n "$new" ] && [ "$new" != "$(cat "$stamp" 2>/dev/null || :)" ] &&
        ${asUser} launchctl print "gui/$uid/${label}" >/dev/null 2>&1; then
        timeout 30 sudo --user=${user} -- ${unpark} ||
          echo "wm-handoff: could not unpark windows before reloading ${label}" >&2
        pidOf() { ${asUser} launchctl print "gui/$uid/${label}" 2>/dev/null | grep -m1 'pid =' | tr -dc '0-9'; }
        before="$(pidOf)"
        timeout 30 ${asUser} launchctl kickstart -k "gui/$uid/${label}" || :
        after="$(pidOf)"
        if [ -n "$after" ] && [ "$after" != "$before" ]; then
          mkdir -p ${stampDir}
          printf '%s\n' "$new" >"$stamp"
        else
          echo "wm-handoff: ${label} was not restarted, will retry on the next switch" >&2
        fi
      fi
    '';
}
