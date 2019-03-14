#!/bin/sh

# Usage example:
# timeout 300s mm-wrapper.sh Verizon-LTE-driving -- chromium-browser https://meet.jit.si/z00mz00m4

usage() {
  echo "Usage: $0 network" 1>&2
  exit 1
}

NETWORK="$1"
if [ -z "$NETWORK" ]; then
  usage
fi
shift

UPLINK=/usr/share/mahimahi/traces/"$NETWORK".up
DOWNLINK=/usr/share/mahimahi/traces/"$NETWORK".down
if [ ! -f "$UPLINK" -o ! -f "$DOWNLINK" ]; then
  usage
fi

# about the queue length, it's 100ms for a 2.5Mbps stream.
MM_ARGS="$UPLINK $DOWNLINK"
MM_ARGS="$ARGS --uplink-queue=droptail --uplink-queue-args=bytes=3125"
MM_ARGS="$ARGS --downlink-queue=droptail --downlink-queue-args=bytes=3125"

exec mm-delay 50 mm-link "$UPLINK" "$DOWNLINK" "$@"
