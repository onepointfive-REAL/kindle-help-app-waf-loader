#!/bin/sh
# Name: Help App WAF Loader
# Author: onepointfive-REAL (github)

WAF_DIR=/mnt/us/waf
HELP_DIR=/var/local/mesquite/help

ERROR_TITLE='Error'
ERROR_TEXT='Failed to load WAF (unknown error)'
ERROR_URL=$(printf '%s' "$ERROR_TEXT" | sed 's/ /%20/g')
ERROR_ARGUMENTS="app://com.lab126.helpapp?%7B%22title%22%3A%22$ERROR_TITLE%22%2C%22url%22%3A%22data%3Atext%2Fhtml%2C%3Ch1%3E$ERROR_URL%3C%2Fh1%3E%22%7D"

callerror() {
    title="$1"
    text="$2"
    json='{ "clientParams":{ "alertId":"appAlert1", "show":true, "customStrings":[ { "matchStr":"alertTitle", "replaceStr":"'"$title"'" }, { "matchStr":"alertText", "replaceStr":"'"$text"'" } ] } }'
    lipc-set-prop com.lab126.pillow pillowAlert "$json"
}

if [ ! -d "$WAF_DIR" ]; then
    echo "Directory $WAF_DIR does not exist" >&2
    callerror "Error" "Directory $WAF_DIR does not exist"
    exit 1
elif [ ! -f "$WAF_DIR/config.xml" ]; then
    echo "No config.xml found in $WAF_DIR" >&2
    callerror "Error" "No config.xml found in $WAF_DIR"
    exit 1
fi

mount | grep -q "on $HELP_DIR " && umount "$HELP_DIR"
mount --bind "$WAF_DIR" "$HELP_DIR" || {
	echo "Error binding $WAF_DIR to $HELP_DIR"
    callerror "Error" "Error binding $WAF_DIR to $HELP_DIR"
    exit 1
}

# If the old help app somehow falls back, use that to our advantage and show error text 
lipc-set-prop com.lab126.appmgrd start "$ERROR_ARGUMENTS"

(
	i=0
    while [ "$(lipc-get-prop com.lab126.appmgrd activeApp)" != "com.lab126.helpapp" ]
    do
		if [ "$i" -eq 2 ]; then
			umount "$HELP_DIR"
			lipc-set-prop com.lab126.appmgrd start "app://com.lab126.KPPMainApp?view=KPP_HOME"
			echo "App at $WAF_DIR failed to start"
			callerror "Error" "App at $WAF_DIR failed to start"
			exit 1
		fi
		i=$((i + 1))
        sleep 1
    done

    while [ "$(lipc-get-prop com.lab126.appmgrd activeApp)" = "com.lab126.helpapp" ]
    do
        sleep 1
    done

    umount "$HELP_DIR"
) &

exit 0
