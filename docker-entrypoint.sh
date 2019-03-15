#! /bin/bash

set -e

if [ "$1" = 'java' ]; then
	chown -R mirth /opt/mirthconnect/appdata
	exec gosu mirth "$@"
fi

exec "$@"
