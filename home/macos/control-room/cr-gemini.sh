# cr-gemini — run Gemini CLI inside a Herdr pane with restart-resume support.
#
# Herdr has no official Gemini integration yet, so after a reboot a Gemini
# pane would come back as a bare shell. This wrapper reports its own resume
# command to Herdr ("cr-gemini --resume"), which Herdr runs on restore; that
# reopens the latest Gemini session for the pane's directory.

resume=0
if [ "${1:-}" = "--resume" ]; then
  resume=1
  shift
fi

source_id="control-room.gemini"
if [ -n "${HERDR_PANE_ID:-}" ] && command -v herdr >/dev/null 2>&1; then
  herdr pane report-agent-session "$HERDR_PANE_ID" \
    --source "$source_id" --agent gemini -- cr-gemini --resume >/dev/null 2>&1 || true
fi

status=0
if [ "$resume" = 1 ]; then
  started=$SECONDS
  gemini --resume latest "$@" || status=$?
  # No saved session for this directory: Gemini exits almost immediately.
  if [ "$status" -ne 0 ] && [ $((SECONDS - started)) -lt 5 ]; then
    status=0
    gemini "$@" || status=$?
  fi
else
  gemini "$@" || status=$?
fi

# Reached only on a normal exit (a reboot kills this script first), so a
# deliberately closed Gemini session is not resurrected on the next restore.
if [ -n "${HERDR_PANE_ID:-}" ] && command -v herdr >/dev/null 2>&1; then
  herdr pane release-agent "$HERDR_PANE_ID" --source "$source_id" --agent gemini \
    >/dev/null 2>&1 || true
fi
exit "$status"
