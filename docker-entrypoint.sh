#!/bin/bash
set -eu

pidfile="/tmp/pgbouncer.pid"
command="gosu postgres /usr/local/bin/pgbouncer -d /etc/scripts/config/pgbouncer/pgbouncer.ini"

# Proxy signals
function kill_app(){
    kill $(cat $pidfile)
    exit 0 # exit okay
}
trap "kill_app" SIGINT SIGTERM

# Launch daemon
$command
sleep 2

# Loop while the pidfile and the process exist
while [ -f $pidfile ] && kill -0 $(cat $pidfile) ; do
    sleep 0.5
done
exit 1000 # exit unexpected