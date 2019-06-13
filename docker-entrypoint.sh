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

. /etc/profile.d/rvm.sh

[[ -s "/root/.gvm/scripts/gvm" ]] && source "/root/.gvm/scripts/gvm"
. /root/.gvm/scripts/gvm
export GOPATH="/home/golang/"
export PATH="$PATH:/home/golang/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm



if [ "$1" = 'run' ]; then
        mongod --fork --logpath /dev/stdout --port 27017
        redis-server /etc/redis.conf
        chmod +x /setup-agent.sh
        sleep 5
        bash /setup-agent.sh run
else
        exec "$@"
fi

trap shutdown SIGTERM SIGINT
wait $NODE_PID
