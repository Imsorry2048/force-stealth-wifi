#!/system/bin/sh

LOG_FILE="/data/local/tmp/wifi_hostname.log"
mkdir -p /data/local/tmp

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

LAST_STATE="disconnected"

while true; do
    CURRENT_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | head -n 1)

    if [ -n "$CURRENT_IP" ] && [ "$LAST_STATE" = "disconnected" ]; then
        GEN_ID=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 6)
        NEW_NAME="localhost.localdomain-$GEN_ID"

        settings put global device_name "$NEW_NAME"
        settings put system device_name "$NEW_NAME"
        setprop net.hostname "$NEW_NAME"
        setprop persist.sys.device_name "$NEW_NAME"
        echo "$NEW_NAME" > /proc/sys/kernel/hostname

        log_msg "New connection: $NEW_NAME. Triggering Wi-Fi reset..."

        LAST_STATE="connected"

        svc wifi disable
        sleep 2
        svc wifi enable
        
        sleep 7
        
        echo 128 > /proc/sys/net/ipv4/ip_default_ttl
        echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_all
        
        for h in /proc/sys/net/ipv6/conf/*/hop_limit; do
            echo 128 > "$h" 2>/dev/null
        done

        ACTUAL_HL=$(cat /proc/sys/net/ipv6/conf/wlan0/hop_limit 2>/dev/null)
        log_msg "Settings applied. Hostname: $NEW_NAME, TTL: 128, HL: $ACTUAL_HL, ICMP: Ignored"
    fi

    if [ -z "$CURRENT_IP" ] && [ "$LAST_STATE" = "connected" ]; then
        log_msg "Connection lost. Resetting trigger."
        LAST_STATE="disconnected"
    fi

    sleep 10
done