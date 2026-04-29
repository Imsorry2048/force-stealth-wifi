#!/system/bin/sh
MODDIR=${0%/*}
mkdir -p /data/local/tmp
chmod 777 /data/local/tmp
chmod +x $MODDIR/wifi_monitor.sh