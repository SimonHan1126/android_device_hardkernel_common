#!/system/bin/sh
while true; do
  /system/bin/sh /system/etc/prune_logs.sh
  sleep 3600
done
