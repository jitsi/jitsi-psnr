#!/bin/sh
set -e

error_exit() {
  echo "$1" >&2
  exit 1
}

usage() {
  error_exit "Usage: $0 template"
}

echo "capture_frame input_frame psnr"
while read capture_frame new_input_frame; do
  if [ -z "$new_input_frame" ]; then
    continue
  fi

  if [ -n "$input_frame" -a "$input_frame" = "$new_input_frame" ]; then
      echo $capture_frame $input_frame $PSNR
  else
    input_frame=$new_input_frame
    OUTPUT_FRAME="$OUTPUT_FRAMES/$capture_frame.png"
    INPUT_FRAME="$INPUT_FRAMES/$input_frame.png"
    # output and input frames are cropped to the same size and outut as miff
    # to standard out. Then they are both piped to compare to get the match
    # score (from PSNR metric) only.
    # see https://imagemagick.org/discourse-server/viewtopic.php?t=11786
    PSNR=`convert convert "$OUTPUT_FRAME" "$INPUT_FRAME" -crop "$CROP_GEOMETRY" +repage miff:- | compare -metric PSNR - null: 2>&1 || true`
    echo $capture_frame $input_frame $PSNR
  fi
done < /dev/stdin
