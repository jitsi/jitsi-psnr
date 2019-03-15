#!/bin/sh

# Usage example:
# timeout 150s ffmpeg-x11grab.sh Videos/Captures/ATT-LTE-driving-2016_p2p_meet_`date +%s`.mp4
ffmpeg -loglevel quiet -video_size 1280x720 -framerate 30 -f x11grab -draw_mouse 0 -i :0.0 -c:v libx264 -crf 0 -preset ultrafast "$1"
