#!/system/bin/sh
MODDIR=${0%/*}
LOGDIR=$MODDIR/logs
LOGFILE=$LOGDIR/boot.log

mkdir -p $LOGDIR
echo "[$(date)] Rootify Boot Sequence Started" > $LOGFILE

chmod +x $MODDIR/ROOTIFY
chmod +x $MODDIR/bin/*
chmod +x $MODDIR/shell/*.sh

while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done

if [ -z "$(pm list packages com.aby.rootify)" ]; then
  sh $MODDIR/uninstall.sh
  touch $MODDIR/remove
  exit 0
fi

# Initialize via Master Core
$MODDIR/ROOTIFY init >> $LOGFILE 2>&1

# Apply persistent settings via Master Core
$MODDIR/ROOTIFY boot >> $LOGFILE 2>&1

echo "[$(date)] Rootify Boot Sequence Completed" >> $LOGFILE
