#!/bin/bash

set -e

trap "kill -15 -1 && echo all proc killed" TERM KILL INT

if [ "$1" = "ansible-tower" ]; then

	if [[ -a /certs/license ]]; then
		echo "copy new license"
		cp -r /certs/license /etc/tower/license
		chown awx:awx /etc/tower/license
        fi
	
	ansible-tower-service start
	sleep inf & wait
else
	exec "$@"
fi
