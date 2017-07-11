#!/bin/bash
#
set -e

source /opt/bin/functions.sh

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

SERVERNUM=$(get_server_num)

rm -f /tmp/.X*lock

xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
  java ${JAVA_OPTS} -jar /opt/selenium/selenium-server-standalone.jar \
  ${SE_OPTS} &
NODE_PID=$!


source /usr/local/rvm/scripts/rvm

[ -e /etc/profile ] && source /etc/profile ;
[ -e ~/.profile ] && source ~/.profile ;
[ -e ~/.bash_profile ] && source ~/.bash_profile ;
[ -e ~/.bashrc ] && source ~/.bashrc ;

if [ "$1" = 'run' ]; then
        mongod --fork --logpath /dev/stdout --port 27017
        redis-server /etc/redis.conf
        chmod +x /setup-agent.sh
        sleep 30
        bash /setup-agent.sh run
else
        exec "$@"
fi

trap shutdown SIGTERM SIGINT
wait $NODE_PID
