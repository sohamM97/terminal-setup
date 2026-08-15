#!/usr/bin/env bash
# Claude Code status line — progress bar, dynamic colors, Unicode separators
# Input: JSON via stdin

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$(pwd)
cwd="${cwd/#$HOME/\~}"

model=$(echo "$input" | jq -r '.model.display_name // empty')

# Git branch + status
branch=""
raw_cwd="${cwd/#\~/$HOME}"
if git -C "$raw_cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null \
            || git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)

  git_status=$(git -C "$raw_cwd" status --porcelain 2>/dev/null)
  staged_count=0
  modified_count=0
  untracked_count=0
  if [ -n "$git_status" ]; then
    staged_count=$(echo "$git_status" | grep -c '^[MADRC]' 2>/dev/null || echo 0)
    modified_count=$(echo "$git_status" | grep -c '^ [MD]' 2>/dev/null || echo 0)
    untracked_count=$(echo "$git_status" | grep -c '^??' 2>/dev/null || echo 0)
  fi
  git_indicators=""
  ahead=$(git -C "$raw_cwd" rev-list --count @{upstream}..HEAD 2>/dev/null || echo 0)
  behind=$(git -C "$raw_cwd" rev-list --count HEAD..@{upstream} 2>/dev/null || echo 0)
  [ "$ahead" -gt 0 ] 2>/dev/null && git_indicators+="\033[36m↑${ahead}\033[0m"
  [ "$behind" -gt 0 ] 2>/dev/null && git_indicators+="\033[35m↓${behind}\033[0m"
fi

# Context window
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Cost (rounded to 2 decimal places)
cost_usd=$(echo "$input" | jq -r 'if .cost.total_cost_usd then (.cost.total_cost_usd * 100 | round / 100 | tostring) else empty end')

# Build the prompt line
printf '\033[1;34m%s\033[0m' "$cwd"

if [ -n "$branch" ]; then
  printf ' \033[90m│\033[0m \033[1;32m⎇ %s\033[0m' "$branch"
  if [ "$staged_count" -gt 0 ] || [ "$modified_count" -gt 0 ] || [ "$untracked_count" -gt 0 ]; then
    printf ' \033[90m│\033[0m'
    [ "$staged_count" -gt 0 ]   && printf ' \033[32m✚%d\033[0m' "$staged_count"
    [ "$modified_count" -gt 0 ] && printf ' \033[33m✎%d\033[0m' "$modified_count"
    [ "$untracked_count" -gt 0 ] && printf ' \033[90m…%d\033[0m' "$untracked_count"
  fi
  [ -n "$git_indicators" ] && printf ' %b' "$git_indicators"
fi

if [ -n "$model" ]; then
  printf ' \033[90m│\033[0m \033[33m%s\033[0m' "$model"
fi

if [ -n "$used_pct" ]; then
  pct_int="${used_pct%%.*}"
  if [ "$pct_int" -gt 70 ] 2>/dev/null; then
    color="31"
    ctx_icon="✕"
  elif [ "$pct_int" -gt 40 ] 2>/dev/null; then
    color="33"
    ctx_icon="⚠"
  else
    color="32"
    ctx_icon="✓"
  fi

  printf ' \033[%sm[%s %s%%]\033[0m' "$color" "$ctx_icon" "$used_pct"
fi

if [ -n "$cost_usd" ]; then
  printf ' \033[90m│\033[0m \033[36m$%s\033[0m' "$cost_usd"
fi

printf '\n'
