#!/bin/bash
set -e
set -x

if [[ ! -d "$1" ]] ;then
 echo "Usage: $0 <directory>"
 exit
fi

. env.sh

echo "captured-frame-id, source-frame-id"
for i in ${1}/*; do
  frame_id=`./extract-qr-single.sh "$i"`
  echo "`basename $i | sed -e 's/.png//'`, $frame_id"

done
