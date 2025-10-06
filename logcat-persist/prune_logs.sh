#!/system/bin/sh
LOGDIR=/data/vendor/logs
MAX_MB=64
AGE_DAYS=14

# compress rotated logs (skip the active file)
for f in "$LOGDIR"/logcat.txt.[1-9]*; do
  [ -f "$f" ] && [ ! -f "$f.gz" ] && gzip -9 "$f"
done

# drop very old compressed logs
find "$LOGDIR" -type f -name 'logcat.txt.*.gz' -mtime +$AGE_DAYS -delete

# enforce a soft size ceiling
cur=$(du -sm "$LOGDIR" | awk '{print $1}')
if [ "$cur" -gt "$MAX_MB" ]; then
  # delete oldest compressed logs until under MAX_MB
  for f in $(ls -1t "$LOGDIR"/logcat.txt.*.gz 2>/dev/null | tail -r); do
    cur=$(du -sm "$LOGDIR" | awk '{print $1}')
    [ "$cur" -le "$MAX_MB" ] && break
    rm -f "$f"
  done
fi
