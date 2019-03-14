#!/bin/sh
set -e

error_exit() {
  echo "$1" >&2
  exit 1
}

usage() {
  error_exit "Usage: $0 input-file input-file -min-frame number -max-frame number -crop geometry"
}

INPUT="$1"
shift
if [ ! -f "$INPUT" ]; then
  usage
fi

OUTPUT="$1"
shift
if [ ! -f "$OUTPUT" ]; then
  usage
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -min-frame)
      MIN_FRAME="$2"
      shift
      ;;
    -max-frame)
      MAX_FRAME="$2"
      shift
      ;;
    -crop)
      CROP_GEOMETRY="$2"
      shift
      ;;
  esac
  shift
done

if [ -z "$MIN_FRAME" ]; then
  usage
fi

if [ -z "$MAX_FRAME" ]; then
  usage
fi

WORKING_DIR=`basename "$OUTPUT" | cut -d. -f1`
OUTPUT_FRAMES=target/"$WORKING_DIR"/frames
DATA=target/"$WORKING_DIR"/data.csv
INPUT_FRAMES=target/`basename "$INPUT" | cut -d. -f1`/sequenced

echo "frame_num sequence_num psnr" > "$DATA"
for i in `seq $MIN_FRAME $MAX_FRAME`; do
  OUTPUT_FRAME="$OUTPUT_FRAMES"/$i.png
  # Find the corresponding input frame.
  FRAMENO=`basename "$OUTPUT_FRAME" .png`
  SEQNO=`dmtxread -n "$OUTPUT_FRAME" --x-range-max 50 --y-range-min 650 || echo -1`
  INPUT_FRAME="$INPUT_FRAMES/$SEQNO.png"
  if [ ! -f "$INPUT_FRAME" ]; then
    echo $FRAMENO -1 -1 | tee -a "$DATA"
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

    if [ -n "$CROP_GEOMETRY" ]; then
      # output and input frames are cropped to the same size and outut as miff
      # to standard out. Then they are both piped to compare to get the match
      # score (from PSNR metric) only.
      # see https://imagemagick.org/discourse-server/viewtopic.php?t=11786
      PSNR=`convert "$OUTPUT_FRAME" "$INPUT_FRAME" -crop "$CROP_GEOMETRY" +repage miff:- | compare -metric PSNR - null: 2>&1 || true`
    else
      PSNR=`compare "$OUTPUT_FRAME" "$INPUT_FRAME" -metric PSNR null: 2>&1 || true`
    fi
    echo $FRAMENO $SEQNO $PSNR | tee -a "$DATA"
  fi
done
