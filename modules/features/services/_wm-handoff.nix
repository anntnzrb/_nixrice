{ lib, user }: {
  stop =
    {
      label,
      evacuate,
      leftovers ? [ ],
    }:
    ''
      uid="$(id -u ${user})"
      if launchctl print "gui/$uid/${label}" >/dev/null 2>&1; then
        timeout 30 sudo --user=${user} -- ${evacuate} ||
          echo "wm-handoff: could not evacuate windows from ${label}" >&2
        launchctl bootout "gui/$uid/${label}" || :
        for _ in $(seq 100); do
          launchctl print "gui/$uid/${label}" >/dev/null 2>&1 || break
          sleep 0.1
        done
        if launchctl print "gui/$uid/${label}" >/dev/null 2>&1; then
          echo "wm-handoff: ${label} did not stop within 10s" >&2
        fi
      fi
      ${lib.optionalString (
        leftovers != [ ]
      ) "rm -f ${lib.escapeShellArgs leftovers}"}
    '';
}
