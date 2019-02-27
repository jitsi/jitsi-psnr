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
RESFRAMES=target/"$WORKING_DIR"/frames
DIFFERENCES=target/"$WORKING_DIR"/differences
DATA=target/"$WORKING_DIR"/data.csv
SEQUENCED_FRAMES=target/`basename "$INPUT" | cut -d. -f1`/sequenced

# Extract the individual frames from the result video file.
mkdir -p "$RESFRAMES"
if [ -z `ls -A "$RESFRAMES"` ]
then
  FFMPEG_OPTS=(-i "$OUTPUT" -f image2 "$RESFRAMES/%03d.png")
  ffmpeg "${FFMPEG_OPTS[@]}"
fi

mkdir -p "$DIFFERENCES"
echo "frameno,seqno,psnr" > "$DATA"
for RESFRAME in "$RESFRAMES"/*; do
  FRAMENO=`basename "$RESFRAME" .png`
  SEQNO=`dmtxread -n "$RESFRAME" --x-range-max 50 --y-range-min 650`
  SEQUENCED_FRAME="$SEQUENCED_FRAMES/$SEQNO.png"
  DIFFERENCE="$DIFFERENCES/$SEQNO.png"
  PSNR=`compare "$RESFRAME" "$SEQUENCED_FRAME" -metric PSNR "$DIFFERENCE" 2>&1 || true`
  echo $FRAMENO,$SEQNO,$PSNR | tee -a "$DATA"
done
