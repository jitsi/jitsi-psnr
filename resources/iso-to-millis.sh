#!/bin/bash

off=${1:-0}
while read DATE
do
  # example 14:31:33,678,744
  hours=`echo $DATE | cut -d: -f1`
  minutes=`echo $DATE | cut -d: -f2`
  seconds=`echo $DATE | cut -d: -f3 | cut -d, -f1`
  millis=`echo $DATE | cut -d: -f3 | cut -d, -f2`
  echo `expr $hours \* 60 \* 60 \* 1000 + $minutes \* 60 \* 1000 + $seconds \* 1000 + $millis - $off`
done < "${2:-/dev/stdin}"
