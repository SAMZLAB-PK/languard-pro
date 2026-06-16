#!/bin/sh
SDB="/etc/ispdash/schedules.db"
SBLOCK="/etc/ispdash/schedule_blocks.db"
BLOCKED="/etc/ispdash/blocked.db"
LOG="/etc/ispdash/audit.log"

mkdir -p /etc/ispdash
touch "$SDB" "$SBLOCK" "$BLOCKED" "$LOG"

ACTION_SCRIPT="/www/cgi-bin/languard-action-audit.sh"
[ -x "$ACTION_SCRIPT" ] || ACTION_SCRIPT="/www/cgi-bin/languard-action.sh"

now_min="$(date +%H:%M | awk -F: '{print ($1*60)+$2}')"
now_txt="$(date '+%F %T %Z')"

to_min(){
  echo "$1" | awk -F: '{print ($1*60)+$2}'
}

is_allowed_now(){
  st="$1"
  en="$2"
  sm="$(to_min "$st")"
  em="$(to_min "$en")"

  if [ "$sm" = "$em" ]; then
    return 0
  fi

  if [ "$sm" -lt "$em" ]; then
    [ "$now_min" -ge "$sm" ] && [ "$now_min" -lt "$em" ] && return 0
    return 1
  else
    [ "$now_min" -ge "$sm" ] || [ "$now_min" -lt "$em" ] && return 0
    return 1
  fi
}

is_blocked(){
  mac="$1"
  grep -qi "^$mac$" "$BLOCKED" 2>/dev/null
}

is_schedule_blocked(){
  mac="$1"
  grep -qi "^$mac|" "$SBLOCK" 2>/dev/null
}

add_schedule_block(){
  mac="$1"
  awk -F'|' -v m="$mac" 'tolower($1)!=m' "$SBLOCK" > "$SBLOCK.tmp" 2>/dev/null
  echo "$mac|$(date +%s)" >> "$SBLOCK.tmp"
  mv "$SBLOCK.tmp" "$SBLOCK"
}

remove_schedule_block(){
  mac="$1"
  awk -F'|' -v m="$mac" 'tolower($1)!=m' "$SBLOCK" > "$SBLOCK.tmp" 2>/dev/null && mv "$SBLOCK.tmp" "$SBLOCK"
}

while IFS='|' read -r mac enabled start end updated; do
  [ -z "$mac" ] && continue
  [ "$enabled" = "1" ] || continue
  echo "$mac" | grep -Eiq '^[0-9a-f]{2}(:[0-9a-f]{2}){5}$' || continue

  [ -z "$start" ] && start="08:00"
  [ -z "$end" ] && end="23:00"

  if is_allowed_now "$start" "$end"; then
    if is_schedule_blocked "$mac"; then
      QUERY_STRING="action=unblock&mac=$mac" "$ACTION_SCRIPT" >/dev/null 2>&1
      remove_schedule_block "$mac"
      echo "$now_txt|local|schedule_unblock|mac=$mac|allowed=$start-$end" >> "$LOG"
    fi
  else
    if ! is_blocked "$mac"; then
      QUERY_STRING="action=block&mac=$mac" "$ACTION_SCRIPT" >/dev/null 2>&1
      add_schedule_block "$mac"
      echo "$now_txt|local|schedule_block|mac=$mac|allowed=$start-$end" >> "$LOG"
    fi
  fi
done < "$SDB"

exit 0
