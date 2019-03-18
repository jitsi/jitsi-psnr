#!/bin/bash

set -e

function error_exit {
  echo "$1" >&2
  exit 1
}

INPUT_FRAMES="$1"
if [ ! -d "$INPUT_FRAMES" ]; then
  error_exit "The input frames directory does not exist."
fi
shift

OUTPUT="$1"
if [ -f "$OUTPUT" ];
then
  error_exit "The output video file already exists."
fi
shift

FRAMERATE=$1
if [ -z "$FRAMERATE" ]; then
  error_exit "The frame rate is required."
fi
shift

PIX_FMT=$1
if [ -z "$PIX_FMT" ]; then
  error_exit "The pixel format is required."
fi

OUTPUT_FRAMES="`echo $OUTPUT | cut -d. -f1`"
BARCODES=target/barcodes

# Inject a sequence number into each frame.
mkdir -p "$BARCODES" "$OUTPUT_FRAMES"
for INPUT_FRAME in "$INPUT_FRAMES"/*
do
  OUTPUT_FRAME="$OUTPUT_FRAMES"/`basename "$INPUT_FRAME"`
  if [ ! -f "$OUTPUT_FRAME" ];
  then
    BARCODE="$BARCODES"/`basename "$INPUT_FRAME"`
    if [ ! -f "$BARCODE" ];
    then
      echo `basename "$INPUT_FRAME" .png`\\c | dmtxwrite -o "$BARCODE" -d 16 -m 1
    fi

    FFMPEG_OPTS=(-i "$INPUT_FRAME" -i "$BARCODE")
    FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -filter_complex overlay=10:10)
    FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" "$OUTPUT_FRAME")
    ffmpeg "${FFMPEG_OPTS[@]}"
  fi
done

FFMPEG_OPTS=(-f image2 -framerate $FRAMERATE -i "$OUTPUT_FRAMES/%03d.png")
FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" -pix_fmt $PIX_FMT)
FFMPEG_OPTS=("${FFMPEG_OPTS[@]}" "$OUTPUT")
ffmpeg "${FFMPEG_OPTS[@]}"
