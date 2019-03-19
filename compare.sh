#!/bin/sh
set -e

error_exit() {
  echo "$1" >&2
  exit 1
}

usage() {
  error_exit "Usage: $0 input-directory input-directory -min-frame number -max-frame number -crop geometry"
}

INPUT_FRAMES="$1"
if [ ! -d "$INPUT_FRAMES" ]; then
  usage
fi
shift

OUTPUT_FRAMES="$1"
if [ ! -d "$OUTPUT_FRAMES" ]; then
  usage
fi
shift

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

DATA=`echo $OUTPUT_FRAMES | sed 's:/*$::'`.csv

echo "frame_num sequence_num psnr" > "$DATA"
for OUTPUT_FRAME in `seq -f "$OUTPUT_FRAMES/%03g.png" $MIN_FRAME $MAX_FRAME`; do
  # Find the corresponding input frame.
  FRAMENO=`basename "$OUTPUT_FRAME" .png`
  #SEQNO=`convert "$OUTPUT_FRAME" -crop 68x68+10+10 miff:- | dmtxread - || echo -1`
  NEW_SEQNO=`convert "$OUTPUT_FRAME" -crop 198x198+9+9 miff:- | convert - -background white -gravity center -extent 300x300 miff:- | dmtxread - | cut -d'\' -f1|| echo -1`
  if [ -n "$SEQNO" -a "$SEQNO" = "$NEW_SEQNO" ]; then
      echo $FRAMENO $SEQNO $PSNR | tee -a "$DATA"
  else
    SEQNO=$NEW_SEQNO
    INPUT_FRAME="$INPUT_FRAMES/$SEQNO.png"
    if [ ! -f "$INPUT_FRAME" ]; then
      echo $FRAMENO -1 -1 | tee -a "$DATA"
    else
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
  fi
done
