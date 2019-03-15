#!/bin/bash

INPUT="$1"
FRAMES="`dirname \"$INPUT\"`/`basename \"$INPUT\" | cut -d. -f1`"

mkdir -p "$FRAMES"
if [ -z "`ls -A \"$FRAMES\"`" ]
then
  FFMPEG_OPTS=(-i "$INPUT" -f image2 "$FRAMES/%03d.png")
  ffmpeg "${FFMPEG_OPTS[@]}"
fi


