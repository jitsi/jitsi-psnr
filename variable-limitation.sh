#!/bin/sh

DEV=enx00e04c112e64 
DURATION=120

tc qdisc del dev $DEV root
sleep $DURATION
tc qdisc add dev $DEV root tbf rate 500kbit burst 5kb latency 70ms
sleep $DURATION
tc qdisc del dev $DEV root
