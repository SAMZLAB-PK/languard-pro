#!/bin/sh
QUERY_STRING="action=create" /www/cgi-bin/languard-backup.sh >/dev/null 2>&1
ls -t /root/languard-backups/lg_manual_*.tar.gz 2>/dev/null | awk 'NR>20{print}' | while read f; do rm -f "$f"; done
exit 0
