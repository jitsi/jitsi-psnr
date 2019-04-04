#!/bin/bash
set -e
#set -x
. env.sh

if [ -z "$1" ] ;then
 echo -1
 exit
fi

qr=`$CONVERT $1 -crop 198x198+9+9 miff:- | $CONVERT - -background white -gravity center -extent 300x300 miff:- | dmtxread - | cut -d'\' -f1`
if [ -z $qr ]  ;then
  qr=-1
fi

echo $qr
