#!/usr/bin/env bash
export DYLD_LIBRARY_PATH=/path/to/ImageMagick-7.0.8/lib
CONVERT=convert
DMTXREAD=dmtxread
FFMPEG=/Applications/ffmpeg
PYTHON=python3

# Directory with the extracted reference frames
SEQUENCE_DIR=/path_to/jiviqa/FourPeople_1280x720_60_sequenced

# Directory with the reference frames with the UI hiding template applied. To generate it, for each reference frame $1:
# $CONVERT "$TEMPLATE_FILE" "$1" -gravity center -compose blend -composite "result.png"
# Then convert them to all to y4m:
# for i in *; do $FFMPEG -i $i -pix_fmt yuv420p `echo $i | sed -e s/png/y4m/`; done
SEQUENCE_TEMPLATE_DIR=/path_to/jiviqa/FourPeople_1280x720_60_sequenced_template

TEMPLATE_FILE=/path_to/jiviqa/template.png


