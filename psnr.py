#!/usr/bin/env python

import pandas as pd
import sys
import os

def next_frame_real(f):
    if f == 600:
        return 1
    if f == 601:
        return 2
    return f + 2


# Gives the next expected frame number. We use just +1 for the testing toy
# model, but for the actual data we need next_frame_real which takes into
# account the conversion from 60fps to 30fps at the source
def next_frame(f):
    return next_frame_real(f)

# Computes the psnr between a captured frame and a refenrence frame. Prints to
# stdout, diagnostic output goes to stderr.
def compute_diff(captured_frame_id, source_frame_id):
    print(str(source_frame_id)+" "+str(captured_frame_id))

def error(x):
    print(x, file=sys.stderr)

# Usage $0 qr.csv capture_dir min max, where:
#    qr.csv has the format (captured_frame_id, qr_code)
#    capture_dir contains the captured frames named %05d.png
#    min, max are the minimum and maximum captured frame IDs to process
#
# The results go to stdout, stderr has debug info
df = pd.read_csv(sys.stdin, delimiter=' ')

print("input_frame capture_frame")
previous_source_frame_id = -1
for x, row in df.iterrows():
    capture_frame_id = int(row[0])
    source_frame_id = -1
    try:
        source_frame_id = int(row[1]) #some qr codes actually parse incorrectly ("j3l")
    except ValueError:
        source_frame_id = -1

    if source_frame_id > 601 or source_frame_id == 0:
        error("invalid frame num:"+str(capture_frame_id)) #and some parse as a number, but outside the range
        continue

    if source_frame_id == -1:
        error("no qr code")
        continue

    # the first frame we're processing
    if previous_source_frame_id == -1:
        compute_diff(capture_frame_id, source_frame_id)
        previous_source_frame_id = source_frame_id

    # a freeze, ignore
    if previous_source_frame_id == source_frame_id:
        continue

    # no gaps
    if next_frame(previous_source_frame_id) == source_frame_id:
        compute_diff(capture_frame_id, source_frame_id)
        previous_source_frame_id = source_frame_id
        continue

    gap_size_one = next_frame(next_frame(previous_source_frame_id)) == source_frame_id
    error("hit a gap, previous="+str(previous_source_frame_id) + " capture="+str(capture_frame_id) + " gap_size_one="+str(gap_size_one))
    previous_source_frame_id = next_frame(previous_source_frame_id)
    while previous_source_frame_id != source_frame_id:
        # We ignore gaps of size 1. This might be due to a tiny drift in the rendering times, or due to the jitter buffer
        # emptying gradually.
        if not gap_size_one:
            compute_diff(capture_frame_id-1, previous_source_frame_id)
        previous_source_frame_id = next_frame(previous_source_frame_id)
    compute_diff(capture_frame_id, source_frame_id)
