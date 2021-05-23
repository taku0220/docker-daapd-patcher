#!/bin/bash

function loop_quit() {
  echo "$0 clean processes"
  echo "Main PID : $$"

  TERM1=$(ps | grep -v grep | grep "/usr/bin/btmon")
  if [ $? -eq 0 ]; then
    TERM1=$(echo $TERM1 | awk END'{print $1}')
    [ -n $TERM1 ] && kill -s SIGTERM $TERM1 > /dev/null 2>&1
    [ $? -eq 0 ] && echo "TERM : btmon (pid:$TERM1)"
  fi

  exit 0
}

sleep 5

trap 'loop_quit' {1,2,3,15}

while BTCMD= read -r line; do
  # printf '%s\n' "$line"
  BTCMD=$(echo $line | awk '{print $7}')
  case "$BTCMD" in
    "44" ) echo "$line : PLAY"
	   curl -X PUT "http://localhost:3689/api/player/toggle" & ;;

    "46" ) echo "$line : PAUSE"
	   curl -X PUT "http://localhost:3689/api/player/toggle" & ;;

    "4b" ) echo "$line : FORWARD"
	   curl -X PUT "http://localhost:3689/api/player/next" & ;;

    "4c" ) echo "$line : BACKWARD"
	   curl -X PUT "http://localhost:3689/api/player/previous" & ;;
  esac
done < <(stdbuf -oL /usr/bin/btmon | stdbuf -oL grep -E "^\s{8}\w0\s11\s\w{2}\s\w{2}\s48\s7c\s4\w\s00")
