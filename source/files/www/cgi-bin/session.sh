#!/bin/sh

FILE="/tmp/lg_session"

echo "Content-Type: text/plain"
echo ""

ACTION=$(echo "$QUERY_STRING" | grep -o 'action=[^&]*' | cut -d= -f2)

if [ "$ACTION" = "login" ]; then
  USER=$(echo "$QUERY_STRING" | grep -o 'user=[^&]*' | cut -d= -f2)
  PASS=$(echo "$QUERY_STRING" | grep -o 'pass=[^&]*' | cut -d= -f2)

  if [ "$USER" = "admin" ] && [ "$PASS" = "admin123" ]; then
    echo "OK"
    echo "1" > $FILE
  else
    echo "ERR"
  fi
fi

if [ "$ACTION" = "check" ]; then
  [ -f "$FILE" ] && cat $FILE || echo "0"
fi
