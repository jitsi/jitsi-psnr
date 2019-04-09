#!/bin/sh

reference_frames="$1"
shift

if [ ! -d "$reference_frames" ]; then
  echo "Usage: $0 reference-frames reconstructed-videos"
  exit 1
fi

pipeline_cleanup() {
  rm -rf "$reconstructed_frames"
}

pipeline_maybe_expand() {
  if [ ! -d $reconstructed_frames ]; then
    mkdir $reconstructed_frames
    ffmpeg -i $reconstructed_video -f image2 $reconstructed_frames/%d.png
  fi
}

pipeline_maybe_map() {
  if [ ! -f $map ]; then
    pipeline_maybe_expand
    ./map.sh $reconstructed_frames | tee $map
  fi
}

for reconstructed_video in "$@"; do
  reconstructed_frames=`dirname $reconstructed_video`/`basename $reconstructed_video .mp4`
  map=$reconstructed_frames.map
  freezes=$reconstructed_frames.freezes
  psnr=$reconstructed_frames.psnr
  debug_log=$reconstructed_frames.log
  error_log=$reconstructed_frames.err

  if [ ! -f $freezes ]; then
    pipeline_maybe_map
    cat $map \
      | python3 analyze.py trim | tee $debug_log \
      | python3 analyze.py augment | tee $debug_log \
      | python3 analyze.py describe | tee $freezes
  fi

  if [ ! -f $psnr ]; then
    pipeline_maybe_map
    pipeline_maybe_expand
    cat $map \
      | python3 analyze.py trim | tee $debug_log \
      | python3 analyze.py augment | tee $debug_log \
      | python3 psnr.py 2>> $error_log \
      | ./compare.sh $reference_frames $reconstructed_frames | tee $psnr
  fi

  pipeline_cleanup
done
