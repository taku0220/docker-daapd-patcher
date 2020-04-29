#!/bin/bash

bt_ret0=$(bluetoothctl show | awk 'NR==1')
if [[ ${bt_ret0} = "No default controller available" ]]; then
  echo "BT no controllers Exit"
else
  for i in `seq 1 20`
  do
    bluetoothctl power on  > /dev/null
    bt_ret=$(bluetoothctl show | grep Powered | awk -F'[:]' '{print $2}')
    if [[ ${bt_ret} = " yes" ]]; then
      echo "BT Power OK"
      break
    fi
    echo "BT Power NG :${i}"
    sleep 15s
  done
fi

if [[ $i -eq 20 ]]; then
  echo "Error : BT power scan timeout"
fi
