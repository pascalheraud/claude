#!/usr/bin/env bash
# PreToolUse guard for Bash: only allows git subcommands known to be
# read-only inspection commands (status, diff, log, branch listing,
# show, blame, stash list/show). Everything else under "git" is denied
# by default, since a whitelist can't be defeated by a subcommand we
# forgot to blacklist (e.g. "git worktree"). See the git-readonly skill.
set -euo pipefail

input="$(cat)"
cmd="$(jq -r '.tool_input.command // ""' <<<"$input")"

allow() {
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow"}}'
  exit 0
}

deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
}

# Fast path: no "git" word anywhere in the command.
if ! grep -qiwE 'git' <<<"$cmd"; then
  allow
fi

# Split on common shell separators so each chained git invocation is checked.
segments="$(sed -E 's/(&&|\|\||;|\|)/\n/g' <<<"$cmd")"

while IFS= read -r seg; do
  [[ -z "$seg" ]] && continue
  # Only segments that actually invoke "git" as a command word.
  echo "$seg" | grep -qE '(^|[[:space:];|&])git([[:space:]]|$)' || continue

  args="$(echo "$seg" | sed -E 's/.*\bgit\b//')"
  sub="$(awk '{for(i=1;i<=NF;i++){if($i !~ /^-/){print $i; exit}}}' <<<"$args")"
  second="$(awk '{f=0; for(i=1;i<=NF;i++){if($i !~ /^-/){f++; if(f==2){print $i; exit}}}}' <<<"$args")"

  case "$sub" in
    status|diff|log|show|blame) ;; # read-only
    branch)
      if echo "$args" | grep -qE '(^|[[:space:]])(-d|-D|--delete)([[:space:]]|$)'; then
        deny "git branch deletion is not allowed (read-only git policy); listing branches is fine"
      fi
      ;; # listing/inspection forms are read-only
    stash)
      case "$second" in
        list|show) ;; # read-only
        *) deny "git stash mutates the working tree (only 'git stash list'/'show' are allowed)";;
      esac
      ;;
    *)
      deny "git $sub is not in the read-only allowlist (status, diff, log, branch listing, show, blame, stash list/show) and is not allowed"
      ;;
  esac
done <<<"$segments"

allow
