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
  # Find the corresponding input frame.
  FRAMENO=`basename "$OUTPUT_FRAME" .png`
  SEQNO=`dmtxread -n "$OUTPUT_FRAME" --x-range-max 50 --y-range-min 650 || echo -1`
  INPUT_FRAME="$INPUT_FRAMES/$SEQNO.png"
  if [ ! -f "$INPUT_FRAME" ]; then
    echo $FRAMENO,-1,-1 | tee -a "$DATA"
  else

    # Identify the input frame and potentially resize the output frame to the
    # input frame geometry before comparing.
    INPUT_GEOMETRY=`identify "$INPUT_FRAME" | rev | cut -d' ' -f7 | rev`
    OUTPUT_GEOMETRY=`identify "$OUTPUT_FRAME" | rev | cut -d' ' -f7 | rev`
    if [ $INPUT_GEOMETRY != $OUTPUT_GEOMETRY ]; then
      RESIZED_FRAMES=target/"$WORKING_DIR"/$INPUT_GEOMETRY
      mkdir -p "$RESIZED_FRAMES"
      OUTPUT_FRAME_RESIZED="$RESIZED_FRAMES/$FRAMENO.png"
      if [ ! -f "$OUTPUT_FRAME_RESIZED" ]; then
        # For some bizzare reason Windows captures 1376x776, which is different
        # than the native screen resolution (1366x768).
        convert "$OUTPUT_FRAME" -resize ${INPUT_GEOMETRY}! "$OUTPUT_FRAME_RESIZED"
      fi
      OUTPUT_FRAME="$OUTPUT_FRAME_RESIZED"
    fi

    DIFFERENCE="$DIFFERENCES/$FRAMENO.png"
    PSNR=`compare "$OUTPUT_FRAME" "$INPUT_FRAME" -metric PSNR "$DIFFERENCE" 2>&1 || true`
    echo $FRAMENO,$SEQNO,$PSNR | tee -a "$DATA"
  fi
done
