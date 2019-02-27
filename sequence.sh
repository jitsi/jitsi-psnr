#!/bin/sh

set -e

function error_exit {
  echo "$1" >&2
  exit 1
}

INPUT="$1"
if [ ! -f "$INPUT" ]; then
  error_exit "The input file does not exist."
fi

OUTPUT=target/`basename "$INPUT"`
if [ -f "$OUTPUT" ];
then
  error_exit "The output video file already exists."
fi

SEQUENCED_FRAMES=target/`basename "$INPUT" | cut -d. -f1`/sequenced
RAW_FRAMES=target/`basename "$INPUT" | cut -d. -f1`/raw
BARCODES=target/barcodes

FRAMERATE=`ffprobe -show_streams "$INPUT" 2> /dev/null | grep codec_time_base | cut -d/ -f2`

# Extract the individual frames from the input video file.
mkdir -p "$RAW_FRAMES"
if [ -z `ls -A "$RAW_FRAMES"` ]
then
  CODED_HEIGHT=`ffprobe -show_streams "$INPUT" 2> /dev/null | grep coded_height | cut -d= -f2`
  CODED_WIDTH=`ffprobe -show_streams "$INPUT" 2> /dev/null | grep coded_width | cut -d= -f2`
  VIDEO_SIZE=${CODED_WIDTH}x${CODED_HEIGHT}

  FFMPEG_OPTS=(-i "$INPUT")
  FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -framerate $FRAMERATE)
  FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -video_size $VIDEO_SIZE)
  FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -f image2 "$RAW_FRAMES/%03d.png")
  ffmpeg "${FFMPEG_OPTS[@]}"
fi

# Inject a sequence number into each frame.
mkdir -p "$BARCODES" "$SEQUENCED_FRAMES"
for RAW_FRAME in "$RAW_FRAMES"/*
do
  SEQUENCED_FRAME="$SEQUENCED_FRAMES"/`basename "$RAW_FRAME"`
  if [ ! -f "$SEQUENCED_FRAME" ];
  then
    BARCODE="$BARCODES"/`basename "$RAW_FRAME"`
    if [ ! -f "$BARCODE" ];
    then
      echo `basename "$RAW_FRAME" .png`\\c | dmtxwrite -o "$BARCODE"
    fi

    FFMPEG_OPTS=(-i "$RAW_FRAME" -i "$BARCODE")
    FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -filter_complex overlay=10:10)
    FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" "$SEQUENCED_FRAME")
    ffmpeg "${FFMPEG_OPTS[@]}"
  fi
done

PIX_FMT=`ffprobe -show_streams "$INPUT" 2> /dev/null | grep pix_fmt | cut -d= -f2`
FFMPEG_OPTS=(-f image2 -framerate $FRAMERATE -i "$SEQUENCED_FRAMES/%03d.png")
FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -pix_fmt $PIX_FMT)
FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" "$OUTPUT")
ffmpeg "${FFMPEG_OPTS[@]}"
