#!/bin/sh
# Name: Help App WAF Loader
# Author: onepointfive-REAL (github)
WAF_DIR=/mnt/us/waf
HELP_DIR=/var/local/mesquite/help
TITLE='WAF'

if [ ! -f "$WAF_DIR/index.html" ]; then
    echo "No index.html in $WAF_DIR" >&2
    exit 1
fi

mount | grep -q "on $HELP_DIR " && umount "$HELP_DIR"
mount --bind "$WAF_DIR" "$HELP_DIR" || exit 1

lipc-set-prop com.lab126.appmgrd start "app://com.lab126.helpapp?%7B%22title%22%3A%22$TITLE%22%7D"

(
    sleep 3
    while [ "$(lipc-get-prop com.lab126.appmgrd activeApp)" = "com.lab126.helpapp" ]; do
        sleep 1
    done
    umount "$HELP_DIR" 2>/dev/null
) >/dev/null 2>&1 &

exit 0
