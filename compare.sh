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

OUTPUT="$2"
if [ ! -f "$OUTPUT" ]; then
  error_exit "The output file does not exist."
fi

WORKING_DIR=`basename "$OUTPUT" | cut -d. -f1`
OUTPUT_FRAMES=target/"$WORKING_DIR"/frames
DIFFERENCES=target/"$WORKING_DIR"/differences
DATA=target/"$WORKING_DIR"/data.csv
INPUT_FRAMES=target/`basename "$INPUT" | cut -d. -f1`/sequenced

# Extract the individual frames from the output video file.
mkdir -p "$OUTPUT_FRAMES"
if [ -z "`ls -A \"$OUTPUT_FRAMES\"`" ]
then
  FFMPEG_OPTS=(-i "$OUTPUT" -f image2 "$OUTPUT_FRAMES/%03d.png")
  ffmpeg "${FFMPEG_OPTS[@]}"
fi

mkdir -p "$DIFFERENCES"
echo "frameno,seqno,psnr" > "$DATA"
for OUTPUT_FRAME in "$OUTPUT_FRAMES"/*; do
  FRAMENO=`basename "$OUTPUT_FRAME" .png`
  SEQNO=`dmtxread -n "$OUTPUT_FRAME" --x-range-max 50 --y-range-min 650`
  INPUT_FRAME="$INPUT_FRAMES/$SEQNO.png"
  DIFFERENCE="$DIFFERENCES/$SEQNO.png"
  PSNR=`compare "$OUTPUT_FRAME" "$INPUT_FRAME" -metric PSNR "$DIFFERENCE" 2>&1 || true`
  echo $FRAMENO,$SEQNO,$PSNR | tee -a "$DATA"
done
