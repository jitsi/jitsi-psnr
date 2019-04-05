#!/bin/sh
set -e

error_exit() {
  echo "$1" >&2
  exit 1
}

usage() {
  error_exit "Usage: $0 directory"
}

FRAMES_DIR="$1"
if [ ! -d "$FRAMES_DIR" ]; then
  usage
fi
shift

echo "capture_frame input_frame"
FRAME_NO=1
while true; do
 FRAME="$FRAMES_DIR/$FRAME_NO.png" 
 if [ ! -f "$FRAME" ]; then
   break
 fi

 SEQNO=`convert "$FRAME" -crop 198x198+9+9 miff:- | convert - -background white -gravity center -extent 300x300 miff:- | dmtxread -m 100 - | cut -d'\' -f1|| echo -1`
  echo $FRAME_NO $SEQNO
  FRAME_NO=`expr $FRAME_NO + 1`
done
